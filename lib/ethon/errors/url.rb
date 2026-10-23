# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when a curl URL API call fails.
    class Url < EthonError
      def initialize(code)
        message = if Ethon::Curl.respond_to?(:url_strerror)
          Ethon::Curl.url_strerror(code)
        else
          code.to_s
        end
        super("An error occurred handling the URL: #{message}")
      end
    end
  end
end
