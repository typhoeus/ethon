# frozen_string_literal: true
module Ethon
  module Curl

    # Thin wrapper around libcurl's URL API (curl_url).
    class Url < OwnedPointer
      def self.native_release(pointer)
        Curl.url_cleanup(pointer) if Curl.respond_to?(:url_cleanup)
      end

      # Create a URL handle, optionally parsing a URL string.
      #
      # @param [ String, Url, FFI::Pointer, nil ] url The URL, a URL handle
      #   to copy, or a native handle.
      # @param [ Integer, Symbol, Array ] flags CURLU_* flags.
      def initialize(url = nil, flags = 0)
        unless Curl.respond_to?(:url)
          raise NotImplementedError, "curl_url is not supported by this libcurl"
        end

        if url.is_a?(self.class)
          pointer = Curl.url_dup(url)
          raise NoMemoryError, "curl_url_dup failed" if pointer.null?
        elsif url.is_a?(::FFI::Pointer)
          pointer = url
        else
          pointer = Curl.url
          raise NoMemoryError, "curl_url failed" if pointer.null?
        end

        super(pointer)
        set(:url, url, flags) if url && !url.is_a?(::FFI::Pointer)
      end

      # Set a URL part.
      #
      # @param [ Symbol, String ] part The CURLUPart name.
      # @param [ String ] value The new value.
      # @param [ Integer, Symbol, Array ] flags CURLU_* flags.
      #
      # @return [ Url ] self
      def set(part, value, flags = 0)
        check_pid!
        code = Curl.url_set(self, normalize_part(part), value, flags)
        raise Errors::Url.new(code) unless code == :ok

        self
      end

      # Get a URL part.
      #
      # @param [ Symbol, String ] part The CURLUPart name.
      # @param [ Integer, Symbol, Array ] flags CURLU_* flags.
      #
      # @return [ String ] The part value.
      def get(part, flags = 0)
        check_pid!
        output = ::FFI::MemoryPointer.new(:pointer)
        code = Curl.url_get(self, normalize_part(part), output, flags)
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

      def normalize_part(part)
        part.is_a?(String) ? part.to_sym : part
      end
    end
  end
end
