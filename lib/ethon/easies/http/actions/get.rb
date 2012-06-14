module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making GET requests.
        class Get < Action

          # Set url and httpget.
          #
          # @example Setup.
          #   get.set_nothing(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_nothing(easy)
            easy.httpget = true
            easy.url = url
          end

          # Setup url with escaped params and httpget.
          #
          # @example Setup.
          #   get.set_params(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_params(easy)
            easy.httpget = true
            params.escape = true
            easy.url = "#{url}?#{params.to_s}"
          end
        end
      end
    end
  end
end
