# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when curl_multi_wait fails.
    class MultiWait < EthonError
      def initialize(code)
        super("An error occurred waiting on the multi: #{code}")
      end
    end
  end
end
