module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making HEAD requests.
        class Head < Action

          # Setup everything what is necessary for a proper
          # HEAD request.
          #
          # @example Setup.
          #   head.setup(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def setup(easy)
            easy.nobody = true
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
