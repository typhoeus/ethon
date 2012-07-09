module Ethon
  module Easies
    module Http

      # This class knows everything about making PATCH requests.
      class Patch < Request
        include Ethon::Easies::Http::Postable

        # Setup easy to make a PATCH request.
        #
        # @example Setup.
        #   patch.setup(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          easy.customrequest = "PATCH"
        end
      end
    end
  end
end
