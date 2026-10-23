# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when curl_easy_header fails.
    class Header < EthonError
      def initialize(code)
        super("An error occurred reading headers: #{code}")
      end
    end
  end
end
