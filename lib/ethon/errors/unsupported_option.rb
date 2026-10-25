# frozen_string_literal: true
module Ethon
  module Errors

    # Raised when libcurl does not recognize an option.
    #
    # This happens when Ethon knows an option that the loaded libcurl is too
    # old to support, for example an option added in a newer libcurl release.
    class UnsupportedOption < EthonError
      def initialize(option)
        version = begin
          Ethon::Curl.version_info[:version]
        rescue StandardError
          nil
        end
        version = Ethon::Curl.version if version.nil?
        # Inspect so control characters in an untrusted option name cannot
        # inject lines into logs that record the message.
        super("libcurl #{version} does not support the option: #{option.inspect}")
      end
    end
  end
end
