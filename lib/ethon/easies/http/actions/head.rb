module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making HEAD requests.
        class Head < Action

          # Set url and nobody.
          #
          # @example Setup.
          #   get.set_nothing(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_nothing(easy)
            easy.nobody = true
            easy.url = url
          end

          # Setup url with escaped params and nobody.
          #
          # @example Setup.
          #   get.set_params(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_params(easy)
            easy.nobody = true
            params.escape = true
            easy.url = "#{url}?#{params.to_s}"
          end
        end
      end
    end
  end
end
