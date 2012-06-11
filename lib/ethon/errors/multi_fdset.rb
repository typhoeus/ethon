module Ethon
  module Errors

    # Raises when multi_fdset failed.
    class MultiFdset < EthonError
      def initialize(code)
        super("An error occured getting the fdset: #{code}")
        # "an error occured getting the fdset: #{code}: #{Curl.multi_strerror(code)}"
      end
    end
  end
end
