# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when libcurl rejects an option value.
    class SetOption < EthonError
      def initialize(option, code, type = :easy)
        message = begin
          strerror(type, code)
        rescue StandardError
          code.to_s
        end
        # Inspect so control characters in an untrusted option name cannot
        # inject lines into logs that record the message.
        super("libcurl failed to set the option: #{option.inspect}: #{message} (#{code})")
      end

      private

      # Multi and easy codes overlap, so decode with the matching strerror.
      def strerror(type, code)
        func = type == :multi ? :multi_strerror : :easy_strerror
        Ethon::Curl.respond_to?(func) ? Ethon::Curl.public_send(func, code) : code.to_s
      end
    end
  end
end
