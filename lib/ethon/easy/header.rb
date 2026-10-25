# frozen_string_literal: true
module Ethon
  class Easy
    # This module contains the logic around adding headers to libcurl.
    #
    # @api private
    module Header
      # Return the request headers, return empty hash if none.
      #
      # The returned hash is an independent snapshot of the headers that were
      # sent to libcurl. Mutating the hash or a value passed to #headers=
      # afterwards cannot change either the handle or this snapshot, and
      # mutating the returned hash or its values does not change the request.
      #
      # @example Return the request headers.
      #   easy.request_headers
      #
      # @return [ Hash ] The request headers.
      def request_headers
        copy_headers(@headers || {})
      end

      # Set the headers.
      #
      # @example Set the headers.
      #   easy.headers = {'User-Agent' => 'ethon'}
      #
      # @param [ Hash ] headers The headers.
      def headers=(value)
        # Snapshot before building the list so the stored value is exactly the
        # set that libcurl accepted. Copy the values too: mutating a
        # caller-owned header value in place would otherwise change the
        # snapshot.
        headers = copy_headers(value || {})
        list = build_slist(headers)
        begin
          Curl.set_option(:httpheader, list, handle)
        rescue Exception
          Curl.slist_free_all(list) if list
          raise
        end

        @headers = headers.freeze
        @header_list = list && Curl::Slist.new(list)
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
        # libcurl sends custom headers verbatim, so CR/LF would inject
        # additional headers into the request.
        Util.validate_header_line(:headers, header)
      end

      private

      # Copy a header hash so callers and the Easy cannot change each other's
      # header values in place. Values that cannot be copied are kept as they
      # are; header values are normally strings.
      def copy_headers(headers)
        headers.each_with_object({}) do |(key, value), copy|
          copy[key] = begin
            value.dup
          rescue TypeError
            value
          end
        end
      end

      # Build a curl_slist for the headers. Compose first so an invalid header
      # does not leave a partial native list behind.
      def build_slist(headers)
        Curl::Slist.build(headers.map { |key, value| compose_header(key, value) })
      end
    end
  end
end
