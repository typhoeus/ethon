# frozen_string_literal: true
module Ethon
  class Easy
    module Url
      attr_reader :curlu

      # Install a URL handle as the request target.
      #
      # @param [ Ethon::Curl::Url, nil ] url The URL handle.
      #
      # @return [ Ethon::Curl::Url, nil ] The URL handle.
      def curlu=(url)
        url.check_pid! if url.respond_to?(:check_pid!)
        Curl.set_option(:curlu, url, handle)
        @curlu = url
        url
      end
    end

    include Url
  end
end
