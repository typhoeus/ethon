module Ethon
  module Easies
    module Http

      # This class knows everything about making HEAD requests.
      class Head
        include Ethon::Easies::Http::Actionable
        include Ethon::Easies::Http::Postable

        # Setup easy to make a HEAD request.
        #
        # @example Setup.
        #   get.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          easy.nobody = true
        end
      end
    end
  end
end
