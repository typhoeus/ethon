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

      # @param [ Ethon::Easy, Curl::EasyHandle, FFI::Pointer ] easy The easy
      #   handle used to create the MIME structure.
      def initialize(easy)
        Curl.init
        unless Curl.respond_to?(:mime_init)
          raise NotImplementedError, "curl_mime_init is not supported by this libcurl"
        end

        easy_handle = mime_easy_handle(easy)
        pointer = Curl.mime_init(easy_handle)
        raise NoMemoryError, "curl_mime_init failed" if pointer.null?

        @easy = easy
        super(pointer)
      end

      # Add a part to the MIME structure.
      #
      # @return [ MimePart ] The new part.
      def addpart
        check_pid!
        pointer = Curl.mime_addpart(self)
        raise NoMemoryError, "curl_mime_addpart failed" if pointer.null?

        part = MimePart.new(pointer, self)
        (@parts ||= []) << part
        part
      end

      private

      # libcurl dereferences the easy handle while creating a MIME structure,
      # so a Multi or another owned pointer would corrupt memory.
      def mime_easy_handle(easy)
        case easy
        when Ethon::Easy
          easy.handle
        when Ethon::Curl::EasyHandle
          easy.check_pid!
          easy
        when Ethon::Curl::OwnedPointer
          raise TypeError, "expected an Ethon::Easy or easy handle, got #{easy.class}"
        when ::FFI::Pointer
          raise ArgumentError, "cannot create a MIME structure for a null easy handle" if easy.null?

          easy
        else
          raise TypeError, "expected an Ethon::Easy or easy handle, got #{easy.class}"
        end
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
        call(:mime_name, header_line(:name, value))
        value
      end

      def filename=(value)
        call(:mime_filename, header_line(:filename, value))
        value
      end

      def type=(value)
        call(:mime_type, header_line(:type, value))
        value
      end

      def encoder=(value)
        call(:mime_encoder, header_line(:encoder, value))
        value
      end

      def file=(value)
        call(:mime_filedata, value.nil? ? nil : native_string(:file, value))
        value
      end

      def data=(value)
        if value.nil?
          call(:mime_data, nil, 0)
        else
          data = value.to_s
          call(:mime_data, data, data.bytesize)
        end
        value
      end

      # Set extra headers for this part.
      #
      # @param [ String, Array<String>, Hash, Curl::Slist, nil ] value The
      #   headers to add. Strings, arrays and hashes are converted into a
      #   curl_slist owned by libcurl.
      #
      # @return [ Object ] The value.
      def headers=(value)
        @mime.check_pid!
        list = nil
        retained = nil
        owned = false

        if value.nil?
          # Clear the headers.
        elsif value.is_a?(Curl::Slist)
          value.check_pid!
          list = value
          retained = value
        else
          lines = value.is_a?(Hash) ? value.map { |key, item| "#{key}: #{item}" } : Array(value)
          lines = header_lines(lines)
          list = Curl::Slist.build(lines)
          owned = !list.nil?
        end

        code = Curl.mime_headers(@handle, list, owned ? 1 : 0)
        unless code == :ok
          Curl.slist_free_all(list) if owned
          raise Errors::Mime.new(code)
        end

        # The previous list must stay reachable until libcurl replaces it.
        @headers_list = retained
        value
      end

      private

      # Convert a value to the C string libcurl receives, rejecting embedded
      # NUL bytes with Ethon's error type instead of FFI's ArgumentError.
      def native_string(option, value)
        string = value.to_s
        if string.include?("\0")
          raise Errors::InvalidValue.new(option, value)
        end
        string
      end

      # The content type and encoder are written into the part headers
      # verbatim, so CR or LF would add headers to the part or the request.
      # A nil value clears the field instead of setting an empty string.
      def header_line(option, value)
        return if value.nil?

        Ethon::Easy::Util.validate_header_line(option, native_string(option, value))
      end

      # Normalize header lines and reject values libcurl would send verbatim
      # as additional part headers.
      def header_lines(lines)
        # An empty line describes no header, so drop it. That also makes a
        # single empty string clear the part headers.
        lines.map(&:to_s).reject(&:empty?).map do |line|
          Ethon::Easy::Util.validate_header_line(:headers, line)
        end
      end

      def call(function, *args)
        @mime.check_pid!
        code = Curl.public_send(function, @handle, *args)
        raise Errors::Mime.new(code) unless code == :ok

        code
      end
    end
  end
end
