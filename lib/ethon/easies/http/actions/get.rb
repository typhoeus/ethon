module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making GET requests.
        class Get < Action

          # Setup everything what is necessary for a proper
          # GET request.
          #
          # @example Setup.
          #   get.setup(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def setup(easy)
            easy.httpget = true
            if params.empty?
              easy.url = url
            else
              params.escape = true
              easy.url = "#{url}?#{params.to_s}"
            end
          end
        end
      end
    end
  end
end
