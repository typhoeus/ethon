# frozen_string_literal: true
module Ethon
  module Errors

    # Raises when multi_fdset failed.
    class MultiFdset < EthonError
      def initialize(code)
        super("An error occurred getting the fdset: #{code}")
      end
    end
  end
end
