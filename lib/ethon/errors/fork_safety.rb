# frozen_string_literal: true
module Ethon
  module Errors
    class ForkSafety < EthonError
      def initialize(message = "Ethon cannot use libcurl initialized before a fork; use fork+exec or initialize libcurl after forking")
        super(message)
      end
    end
  end
end
