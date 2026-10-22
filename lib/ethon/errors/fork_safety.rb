# frozen_string_literal: true
module Ethon
  module Errors
    class ForkSafety < EthonError
      def initialize
        super("Ethon cannot use libcurl initialized before a fork; create Ethon handles after forking or use fork+exec")
      end
    end
  end
end
