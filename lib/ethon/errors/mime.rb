# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when a curl MIME API call fails.
    class Mime < EthonError
      def initialize(code)
        message = if Ethon::Curl.respond_to?(:easy_strerror)
          Ethon::Curl.easy_strerror(code)
        else
          code.to_s
        end
        super("An error occurred building the MIME form: #{message}")
      end
    end
  end
end
