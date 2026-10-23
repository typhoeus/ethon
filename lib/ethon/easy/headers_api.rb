# frozen_string_literal: true
module Ethon
  class Easy
    # Structured access to response headers via curl_easy_header.
    module HeadersApi
      # Return a parsed response header.
      #
      # @param [ String ] name The header name.
      # @param [ Integer ] index The instance index for repeated headers.
      # @param [ Integer, Symbol, Array ] origin CURLH_* origin bits.
      # @param [ Integer ] request The request number, 0 for the last one.
      #
      # @return [ Ethon::Curl::Header ] The header.
      def header(name, index = 0, origin = Curl::HeaderOrigin[:header], request = 0)
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
      # @param [ Integer ] request The request number, 0 for the last one.
      #
      # @return [ Enumerator, self ] The headers.
      def each_header(origin = Curl::HeaderOrigin[:header], request = 0)
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
          origin.inject(0) { |mask, item| mask | Curl::HeaderOrigin[item] }
        when Symbol
          Curl::HeaderOrigin[origin]
        else
          origin
        end
      end
    end

    include HeadersApi
  end
end
