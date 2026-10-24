# frozen_string_literal: true
module Ethon
  module Errors

    # Raises when global_init failed.
    class GlobalInit < EthonError
      def initialize
        super("An error occurred initializing curl.")
      end
    end
  end
end

