# frozen_string_literal: true
module Ethon
  class Easy
    # This module contains the logic around adding headers to libcurl.
    #
    # @api private
    module Header
      # Return the request headers, return empty hash if none.
      #
      # @example Return the request headers.
      #   easy.request_headers
      #
      # @return [ Hash ] The request headers.
      def request_headers
        @headers ||= {}
      end

      # Set the headers.
      #
      # @example Set the headers.
      #   easy.headers = {'User-Agent' => 'ethon'}
      #
      # @param [ Hash ] headers The headers.
      def headers=(headers)
        headers ||= {}
        header_list = nil
        headers.each do |key, value|
          header_list = Curl.slist_append(header_list, compose_header(key, value))
        end
        Curl.set_option(:httpheader, header_list, handle)

        @headers = headers
        @header_list = header_list && Curl::Slist.new(header_list)
      end
      alias request_headers= headers=

      # Return header_list.
      #
      # @example Return header_list.
      #   easy.header_list
      #
      # @return [ FFI::Pointer ] The header list.
      def header_list
        @header_list
      end

      # Compose libcurl header string from key and value.
      # Also replaces null bytes, because libcurl will complain
      # otherwise.
      #
      # @example Compose header.
      #   easy.compose_header('User-Agent', 'Ethon')
      #
      # @param [ String ] key The header name.
      # @param [ String ] value The header value.
      #
      # @return [ String ] The composed header.
      def compose_header(key, value)
        header = if key.to_s.end_with?(';') && value.to_s.empty?
          key.to_s
        else
          "#{key}: #{value}"
        end
        header = Util.escape_zero_byte(header)
        if header.include?("\r") || header.include?("\n")
          # libcurl sends custom headers verbatim, so CR/LF would inject
          # additional headers into the request.
          raise Errors::InvalidValue.new(:headers, header)
        end
        header
      end
    end
  end
end
