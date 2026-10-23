# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when curl_multi_poll fails.
    class MultiPoll < EthonError
      def initialize(code)
        super("An error occurred polling the multi: #{code}")
      end
    end
  end
end
