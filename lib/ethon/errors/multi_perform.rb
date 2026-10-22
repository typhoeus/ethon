# frozen_string_literal: true
module Ethon
  module Errors

    # Raises when multi_perform failed.
    class MultiPerform < EthonError
      def initialize(code)
        super("An error occurred performing the multi: #{code}")
      end
    end
  end
end
