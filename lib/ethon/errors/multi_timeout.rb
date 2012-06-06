module Ethon
  module Errors
    class MultiTimeout < EthonError
      def initialize(code)
        super("An error occured getting the timeout: #{code}")
        # "An error occured getting the timeout: #{code}: #{Curl.multi_strerror(code)}"
      end
    end
  end
end
