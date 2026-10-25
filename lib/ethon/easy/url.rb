# frozen_string_literal: true
module Ethon
  class Easy
    module Url
      attr_reader :curlu

      # Install a URL handle as the request target.
      #
      # @param [ Ethon::Curl::Url, nil ] url The URL handle.
      #
      # @raise [ TypeError ] If url is not a URL handle.
      #
      # @return [ Ethon::Curl::Url, nil ] The URL handle.
      def curlu=(url)
        unless url.nil? || url.is_a?(Curl::Url)
          raise TypeError, "expected an Ethon::Curl::Url, got #{url.class}"
        end

        url.check_pid! if url
        Curl.set_option(:curlu, url, handle)
        if url
          Curl.set_option(:url, nil, handle)
          @url = nil
        end
        @curlu = url
        url
      end
    end

    include Url
  end
end
