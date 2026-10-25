# frozen_string_literal: true
module Ethon
  module Errors

    # Raises when option is invalid.
    class InvalidOption < EthonError
      def initialize(option)
        # Inspect so control characters in an untrusted option name cannot
        # inject lines into logs that record the message.
        super("The option: #{option.inspect} is invalid.")
      end
    end
  end
end

