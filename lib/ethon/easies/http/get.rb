module Ethon
  module Easies
    module Http

      # This class knows everything about making GET requests.
      class Get
        include Ethon::Easies::Http::Actionable
        include Ethon::Easies::Http::Postable

        # Setup easy to make a GET request.
        #
        # @example Setup.
        #   get.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          easy.customrequest = "GET"
        end
      end
    end
  end
end
