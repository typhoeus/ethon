module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making GET requests.
        class Options < Post

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
end
