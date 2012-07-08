module Ethon
  module Easies
    module Http

      # This class knows everything about making HEAD requests.
      class Head < BaseRequest
        include Ethon::Easies::Http::Postable

        # Setup url with escaped params and nobody.
        #
        # @example Setup.
        #   get.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_customs(easy)
          easy.nobody = true
        end
      end
    end
  end
end
