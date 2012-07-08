module Ethon
  module Easies
    module Http

      # This class knows everything about making OPTIONS requests.
      class Options < BaseRequest
        include Ethon::Easies::Http::Postable

        # Setup url with escaped params and httpget.
        #
        # @example Setup.
        #   get.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_customs(easy)
          easy.customrequest = "OPTIONS"
        end
      end
    end
  end
end
