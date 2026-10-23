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
        owner_pid = OWNERS_MUTEX.synchronize { owners.delete(pointer.address) }
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
      def self.native_release(pointer)
        Curl.multi_cleanup(pointer)
      end
    end

    class Slist < OwnedPointer
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
        Curl.formfree(pointer)
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

    # :nodoc:
    class FDSet < ::FFI::Struct
      if Curl.windows?
        layout :fd_count, :uint,
               # TODO: Make it future proof by dynamically grabbing FD_SETSIZE.
               :fd_array, [:uint, 2048]

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
