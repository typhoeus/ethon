# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when a curl share API call fails.
    class Share < EthonError
      def initialize(code)
        message = if Ethon::Curl.respond_to?(:share_strerror)
          Ethon::Curl.share_strerror(code)
        else
          code.to_s
        end
        super("An error occurred handling the share: #{message}")
      end
    end
  end
end
