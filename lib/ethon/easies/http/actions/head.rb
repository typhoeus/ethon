module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making HEAD requests.
        class Head < Post

          # Setup url with escaped params and nobody.
          #
          # @example Setup.
          #   get.set_params(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_customs(easy)
            super
            easy.nobody = true
          end
        end
      end
    end
  end
end
