# frozen_string_literal: true
module Ethon
  module Errors

    # Raises when option is invalid.
    class InvalidValue < EthonError
      def initialize(option, value)
        # Inspect so control characters in a rejected value cannot inject
        # lines into logs that record the message.
        super("The value: #{value.inspect} is invalid for option: #{option}.")
      end
    end
  end
end

