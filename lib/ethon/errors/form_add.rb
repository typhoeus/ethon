# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when curl_formadd fails.
    class FormAdd < EthonError
      def initialize(code)
        super("An error occurred adding a form field: #{code}")
      end
    end
  end
end
