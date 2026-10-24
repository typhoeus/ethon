# frozen_string_literal: true
module Ethon
  class Easy
    module Share
      attr_reader :share

      # Attach a curl share handle.
      #
      # @param [ Ethon::Curl::Share, nil ] share The share handle.
      #
      # @raise [ TypeError ] If share is not a share handle.
      #
      # @return [ Ethon::Curl::Share, nil ] The share handle.
      def share=(share)
        unless share.nil? || share.is_a?(Curl::Share)
          raise TypeError, "expected an Ethon::Curl::Share, got #{share.class}"
        end

        share.check_pid! if share
        Curl.set_option(:share, share, handle)
        @share = share
        share
      end
    end

    include Share
  end
end
