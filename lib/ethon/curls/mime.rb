# frozen_string_literal: true
module Ethon
  module Curl

    # CURLOPT_MIMEPOST is the modern replacement for the deprecated form API.
    Ethon::Curls::Options.option(:easy, :mimepost, :ffipointer, 269)

    # Owns a curl_mime structure.
    class Mime < OwnedPointer
      def self.native_release(pointer)
        Curl.mime_free(pointer) if Curl.respond_to?(:mime_free)
      end

      # @param [ Ethon::Easy, FFI::Pointer ] easy The easy handle used to
      #   create the MIME structure.
      def initialize(easy)
        unless Curl.respond_to?(:mime_init)
          raise NotImplementedError, "curl_mime_init is not supported by this libcurl"
        end

        @easy = easy
        easy_handle = easy.respond_to?(:handle) ? easy.handle : easy
        pointer = Curl.mime_init(easy_handle)
        raise NoMemoryError, "curl_mime_init failed" if pointer.null?

        super(pointer)
      end

      # Add a part to the MIME structure.
      #
      # @return [ MimePart ] The new part.
      def addpart
        pointer = Curl.mime_addpart(self)
        raise NoMemoryError, "curl_mime_addpart failed" if pointer.null?

        part = MimePart.new(pointer, self)
        (@parts ||= []) << part
        part
      end
    end

    # A part inside a MIME structure. The part is owned by its Mime.
    class MimePart
      attr_reader :mime, :handle

      def initialize(pointer, mime)
        @handle = pointer
        @mime = mime
      end

      def name=(value)
        call(:mime_name, value.to_s)
        value
      end

      def filename=(value)
        call(:mime_filename, value.to_s)
        value
      end

      def type=(value)
        call(:mime_type, value.to_s)
        value
      end

      def encoder=(value)
        call(:mime_encoder, value.to_s)
        value
      end

      def file=(value)
        call(:mime_filedata, value.to_s)
        value
      end

      def data=(value)
        data = value.to_s
        call(:mime_data, data, data.bytesize)
        value
      end

      def headers=(value)
        code = Curl.mime_headers(@handle, value, 0)
        raise Errors::Mime.new(code) unless code == :ok

        value
      end

      private

      def call(function, *args)
        code = Curl.public_send(function, @handle, *args)
        raise Errors::Mime.new(code) unless code == :ok

        code
      end
    end
  end
end
