# frozen_string_literal: true
module Ethon
  class Easy
    # Structured access to response headers via curl_easy_header.
    module HeadersApi
      # libcurl's request number for the last request in a transfer. Redirects
      # and multi-state authentication can produce several requests, and the
      # response the caller sees comes from the last one.
      LAST_REQUEST = -1

      # Return a parsed response header.
      #
      # @param [ String ] name The header name.
      # @param [ Integer ] index The instance index for repeated headers.
      # @param [ Integer, Symbol, Array ] origin CURLH_* origin bits.
      # @param [ Integer ] request The request number, -1 for the last request.
      #
      # @return [ Ethon::Curl::Header ] The header.
      def header(name, index = 0, origin = Curl::HeaderOrigin[:header], request = LAST_REQUEST)
        unless Curl.respond_to?(:easy_header)
          raise NotImplementedError, "curl_easy_header is not supported by this libcurl"
        end

        output = ::FFI::MemoryPointer.new(:pointer)
        code = Curl.easy_header(handle, name.to_s, index, header_origin(origin), request, output)
        raise Errors::Header.new(code) unless code == :ok

        Curl::Header.new(Curl::HeaderData.new(output.read_pointer))
      end

      # Enumerate response headers.
      #
      # @param [ Integer, Symbol, Array ] origin CURLH_* origin bits.
      # @param [ Integer ] request The request number, -1 for the last request.
      #
      # @return [ Enumerator, self ] The headers.
      def each_header(origin = Curl::HeaderOrigin[:header], request = LAST_REQUEST)
        unless Curl.respond_to?(:easy_nextheader)
          raise NotImplementedError, "curl_easy_nextheader is not supported by this libcurl"
        end

        origin = header_origin(origin)
        return enum_for(:each_header, origin, request) unless block_given?

        previous = nil
        loop do
          header = Curl.easy_nextheader(handle, origin, request, previous)
          break if header.null?

          yield Curl::Header.new(header)
          previous = header
        end
        self
      end
      alias headers_list each_header

      private

      def header_origin(origin)
        case origin
        when Array
          origin.inject(0) do |mask, item|
            value = Curl::HeaderOrigin[item]
            raise Errors::InvalidValue.new(:header_origin, item) unless value && value != 0
            mask | value
          end
        when Symbol
          value = Curl::HeaderOrigin[origin]
          raise Errors::InvalidValue.new(:header_origin, origin) unless value && value != 0
          value
        else
          origin
        end
      end
    end

    include HeadersApi
  end
end
