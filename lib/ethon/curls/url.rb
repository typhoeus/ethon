# frozen_string_literal: true
module Ethon
  module Curl

    # CURLOPT_CURLU takes a CURLU handle.
    Ethon::Curls::Options.option(:easy, :curlu, :ffipointer, 282)

    # Thin wrapper around libcurl's URL API (curl_url).
    class Url < OwnedPointer
      def self.native_release(pointer)
        Curl.url_cleanup(pointer) if Curl.respond_to?(:url_cleanup)
      end

      # Create a URL handle, optionally parsing a URL string.
      #
      # @param [ String, Url, FFI::Pointer, nil ] url The URL, a URL handle
      #   to copy, or a native handle.
      # @param [ Integer, Symbol, Array ] flags CURLU_* flags. These are only
      #   applied when parsing a String; a copied handle already has its parts.
      def initialize(url = nil, flags = 0)
        Curl.init
        unless Curl.respond_to?(:url)
          raise NotImplementedError, "curl_url is not supported by this libcurl"
        end

        copying = url.is_a?(Ethon::Curl::Url)
        if copying
          url.check_pid!
          if normalize_flags(flags) != 0
            raise ArgumentError, "flags cannot be applied when copying an Ethon::Curl::Url"
          end
          # Parsing the copied handle's string form would fail for partial
          # handles and could normalize a complete one. Duplicate the parts
          # instead.
          pointer = Curl.url_dup(url)
          raise NoMemoryError, "curl_url_dup failed" if pointer.null?
        elsif url.is_a?(::FFI::Pointer)
          pointer = url
        else
          pointer = Curl.url
          raise NoMemoryError, "curl_url failed" if pointer.null?
        end

        super(pointer)
        begin
          set(:url, url, flags) if url && !url.is_a?(::FFI::Pointer) && !copying
        rescue Exception
          # A rejected URL must not leave the native handle to the finalizer.
          free
          raise
        end
      end

      # Set a URL part.
      #
      # @param [ Symbol, String, Integer ] part The CURLUPart name or value.
      # @param [ String, nil ] value The new value, or nil to clear the part.
      # @param [ Integer, Symbol, Array ] flags CURLU_* flags.
      #
      # @raise [ Errors::InvalidValue ] If the part or a flag is unknown, or
      #   the value contains a NUL byte.
      #
      # @return [ Url ] self
      def set(part, value, flags = 0)
        check_pid!
        code = Curl.url_set(self, normalize_part(part), normalize_value(value),
                            normalize_flags(flags))
        raise Errors::Url.new(code) unless code == :ok

        self
      end

      # Get a URL part.
      #
      # @param [ Symbol, String, Integer ] part The CURLUPart name or value.
      # @param [ Integer, Symbol, Array ] flags CURLU_* flags.
      #
      # @raise [ Errors::InvalidValue ] If the part or a flag is unknown.
      #
      # @return [ String ] The part value.
      def get(part, flags = 0)
        check_pid!
        output = ::FFI::MemoryPointer.new(:pointer)
        code = Curl.url_get(self, normalize_part(part), output, normalize_flags(flags))
        raise Errors::Url.new(code) unless code == :ok

        pointer = output.read_pointer
        begin
          pointer.read_string
        ensure
          Curl.free(pointer)
        end
      end

      # Duplicate the URL handle.
      #
      # @return [ Url ] The copied URL.
      def dup
        check_pid!
        pointer = Curl.url_dup(self)
        raise NoMemoryError, "curl_url_dup failed" if pointer.null?

        self.class.new(pointer)
      end

      def to_s
        get(:url)
      end

      private

      # Only names that exist in CURLUPart reach libcurl. FFI would raise its
      # own ArgumentError for anything else. Direct enum values stay supported,
      # like the named option setters.
      def normalize_part(part)
        name = part.is_a?(String) ? part.to_sym : part
        values = Curl::UrlPart.to_h
        unless values.key?(name) || (name.is_a?(Integer) && values.value?(name))
          raise Errors::InvalidValue.new(:url_part, part)
        end

        name
      end

      # libcurl takes a C string, so an embedded NUL would silently truncate
      # the value. nil clears the part.
      def normalize_value(value)
        return if value.nil?

        string = value.to_s
        raise Errors::InvalidValue.new(:url_value, value) if string.include?("\0")

        string
      end

      # Only CURLU_* flag names reach libcurl. FFI would raise its own
      # ArgumentError for anything else. Direct bit values stay supported, like
      # the named option setters.
      def normalize_flags(flags)
        return flags if flags.is_a?(Integer)

        Array(flags).inject(0) { |mask, flag| mask | normalize_flag(flag) }
      end

      def normalize_flag(flag)
        return flag if flag.is_a?(Integer)

        name = flag.is_a?(String) ? flag.to_sym : flag
        value = name.is_a?(Symbol) && Curl::UrlFlags.to_h[name]
        raise Errors::InvalidValue.new(:url_flags, flag) unless value

        value
      end
    end
  end
end
