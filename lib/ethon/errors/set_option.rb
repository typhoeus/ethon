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
        super("libcurl #{version} does not support the option: #{option}")
      end
    end

    # Raised when libcurl rejects an option value.
    class SetOption < EthonError
      def initialize(option, code)
        message = begin
          Ethon::Curl.respond_to?(:easy_strerror) ? Ethon::Curl.easy_strerror(code) : code.to_s
        rescue StandardError
          code.to_s
        end
        super("libcurl failed to set the option: #{option}: #{message} (#{code})")
      end
    end
  end
end
