# frozen_string_literal: true
module Ethon
  class Easy
    module Share
      attr_reader :share

      # Attach a curl share handle.
      #
      # @param [ Ethon::Curl::Share, nil ] share The share handle.
      #
      # @return [ Ethon::Curl::Share, nil ] The share handle.
      def share=(share)
        @share = share
        Curl.set_option(:share, share, handle)
        share
      end
    end

    include Share
  end
end
