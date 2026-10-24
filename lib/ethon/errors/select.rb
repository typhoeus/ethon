# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when select failed.
    class Select < EthonError
      def initialize(errno)
        super("An error occurred on select: #{errno}")
      end
    end
  end
end

