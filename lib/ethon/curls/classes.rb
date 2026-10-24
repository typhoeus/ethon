# frozen_string_literal: true
module Ethon
  module Curl
    class OwnedPointer < ::FFI::AutoPointer
      OWNERS_MUTEX = Mutex.new

      def initialize(pointer)
        super
        @pid = Process.pid
        OWNERS_MUTEX.synchronize { self.class.owners[pointer.address] = @pid }
      end

      def check_pid!
        raise Errors::ForkSafety.new if @pid != Process.pid
      end

      def self.owners
        @owners ||= {}
      end

      def self.release(pointer)
        owner_pid = begin
          OWNERS_MUTEX.synchronize { owners.delete(pointer.address) }
        rescue ThreadError, SignalException
          # Finalizers can run in a trap context where locking is forbidden,
          # or be interrupted by a signal. The process is exiting at this
          # point, so the unsynchronized delete is best effort.
          owners.delete(pointer.address)
        end
        native_release(pointer) if owner_pid == Process.pid
      end
    end

    class EasyHandle < OwnedPointer
      attr_accessor :error_buffer

      def self.native_release(pointer)
        Curl.easy_cleanup(pointer)
      end
    end

    class MultiHandle < OwnedPointer
      CALLBACKS_MUTEX = Mutex.new

      # libcurl may invoke the socket callback from curl_multi_cleanup. Keep
      # callbacks referenced until the native handle is done with them.
      def self.callbacks
        @callbacks ||= {}
      end

      def self.retain_callback(pointer, option, callback)
        key = pointer.address
        CALLBACKS_MUTEX.synchronize do
          if callback
            (callbacks[key] ||= {})[option] = callback
          elsif (registry = callbacks[key])
            registry.delete(option)
            callbacks.delete(key) if registry.empty?
          end
        end
      end

      def self.native_release(pointer)
        Curl.multi_cleanup(pointer)
      ensure
        begin
          CALLBACKS_MUTEX.synchronize { callbacks.delete(pointer.address) }
        rescue ThreadError, SignalException
          # Finalizers can run in a trap context where locking is forbidden.
          callbacks.delete(pointer.address)
        end
      end
    end

    class Slist < OwnedPointer
      # Build a curl_slist from lines. Returns the raw pointer, which is owned
      # by the caller; nil when there are no lines.
      def self.build(lines)
        list = nil
        begin
          lines.each do |line|
            appended = Curl.slist_append(list, line.to_s)
            # libcurl returns NULL (not nil) and leaves the old list intact.
            if appended.nil? || appended.null?
              raise NoMemoryError, "curl_slist_append failed"
            end

            list = appended
          end
          list
        rescue Exception
          Curl.slist_free_all(list) if list
          raise
        end
      end

      def to_a
        SlistNode.to_a(self)
      end

      def self.native_release(pointer)
        Curl.slist_free_all(pointer)
      end
    end

    class SlistNode < ::FFI::Struct
      layout :data, :pointer,
        :next, :pointer

      def self.to_a(pointer)
        values = []
        until pointer.null?
          node = new(pointer)
          values << node[:data].read_string unless node[:data].null?
          pointer = node[:next]
        end
        values
      end
    end

    class FormData < OwnedPointer
      def self.native_release(pointer)
        Curl.formfree(pointer) if Curl.respond_to?(:formfree)
      end
    end

    # struct curl_blob, used by the CURLOPT_*_BLOB options.
    class Blob < ::FFI::Struct
      layout :data, :pointer,
             :len, :size_t,
             :flags, :uint

      # Copy a Ruby String into native memory and return a blob that keeps the
      # copied buffer alive for as long as the blob is retained.
      def self.from_string(value, flags = 0)
        string = value.to_s
        data = ::FFI::MemoryPointer.new(:char, string.bytesize)
        data.put_bytes(0, string)

        blob = new
        blob[:data] = data
        blob[:len] = string.bytesize
        blob[:flags] = flags
        blob.instance_variable_set(:@data, data)
        blob
      end
    end

    # :nodoc:
    class MsgData < ::FFI::Union
      layout :whatever, :pointer, :code, :easy_code
    end

    # :nodoc:
    class Msg < ::FFI::Struct
      layout :code, :msg_code, :easy_handle, :pointer, :data, MsgData
    end

    class VersionInfoData < ::FFI::Struct
      layout :curl_version, :int,
        :version, :string,
        :version_num, :int,
        :host, :string,
        :features, :int,
        :ssl_version, :string,
        :ssl_version_num, :long,
        :libz_version, :string,
        :protocols, :pointer
    end

    # curl_version_info_data through CURLVERSION_ELEVENTH. Only safe to use
    # when the runtime age is at least CURLVERSION_ELEVENTH.
    class VersionInfoDataFull < ::FFI::Struct
      layout :curl_version, :int,
        :version, :string,
        :version_num, :int,
        :host, :string,
        :features, :int,
        :ssl_version, :string,
        :ssl_version_num, :long,
        :libz_version, :string,
        :protocols, :pointer,
        :ares, :string,
        :ares_num, :int,
        :libidn, :string,
        :iconv_ver_num, :int,
        :libssh_version, :string,
        :brotli_ver_num, :uint,
        :brotli_version, :string,
        :nghttp2_ver_num, :uint,
        :nghttp2_version, :string,
        :quic_version, :string,
        :cainfo, :string,
        :capath, :string,
        :zstd_ver_num, :uint,
        :zstd_version, :string,
        :hyper_version, :string,
        :gsasl_version, :string,
        :feature_names, :pointer
    end

    # struct curl_header.
    class HeaderData < ::FFI::Struct
      layout :name, :string,
        :value, :string,
        :amount, :size_t,
        :index, :size_t,
        :origin, :uint,
        :anchor, :pointer

      def name; self[:name]; end
      def value; self[:value]; end
      def amount; self[:amount]; end
      def index; self[:index]; end
      def origin; self[:origin]; end
    end

    # Immutable copy of a curl_header. libcurl reuses the backing struct
    # between curl_easy_nextheader calls, so values must be copied eagerly.
    class Header
      attr_reader :name, :value, :amount, :index, :origin

      def initialize(data)
        @name = data.name
        @value = data.value
        @amount = data.amount
        @index = data.index
        @origin = data.origin
      end
    end

    # struct curl_easyoption.
    class EasyOptionInfo < ::FFI::Struct
      layout :name, :string,
        :id, :easy_option,
        :type, :easy_type,
        :flags, :uint

      def name; self[:name]; end
      def id; self[:id]; end
      def type; self[:type]; end
      def flags; self[:flags]; end
      def alias?; (flags & 1) != 0; end
    end

    # :nodoc:
    class FDSet < ::FFI::Struct
      if Curl.windows?
        layout :fd_count, :uint,
               # SOCKET is UINT_PTR, so use the platform pointer-sized integer.
               # TODO: Make it future proof by dynamically grabbing FD_SETSIZE.
               :fd_array, [:size_t, 2048]

        def clear; self[:fd_count] = 0; end
      else
        # https://github.com/typhoeus/ethon/issues/182
        FD_SETSIZE = begin
          # Allow to override the (new) default cap
          if ENV['ETHON_FD_SIZE']
            ENV['ETHON_FD_SIZE'].to_i

          # auto-detect ulimit, but cap at 2^16
          else
            [::Ethon::Libc.open_max, 65_536].min
          end
        end

        layout :fds_bits, [:long, FD_SETSIZE / ::FFI::Type::LONG.size]

        # :nodoc:
        def clear; super; end
      end
    end

    # :nodoc:
    class Timeval < ::FFI::Struct
      if Curl.windows?
        layout :sec, :long,
               :usec, :long
      else
        layout :sec, :time_t,
               :usec, :suseconds_t
      end
    end

    # :nodoc:
    class Certinfo < ::FFI::Struct
      layout :num_of_certs, :int,
             :certinfo, :pointer
             
      def to_a
        return [] if self[:num_of_certs] == 0
        self[:certinfo].read_array_of_pointer(self[:num_of_certs]).map do |pointer|
          SlistNode.to_a(pointer)
        end
      end
    end
  end
end
