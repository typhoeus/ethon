# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when curl_multi_assign fails.
    class MultiAssign < EthonError
      def initialize(code)
        super("An error occurred assigning the multi socket: #{code}")
      end
    end
  end
end
