module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making GET requests.
        class Get < Action

          def set_nothing(easy)
            easy.httpget = true
            easy.url = url
          end

          def set_params(easy)
            params.escape = true
            easy.url = "#{url}?#{params.to_s}"
          end
        end
      end
    end
  end
end
