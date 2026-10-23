# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when curl_multi_wakeup fails.
    class MultiWakeup < EthonError
      def initialize(code)
        super("An error occurred waking up the multi: #{code}")
      end
    end
  end
end
