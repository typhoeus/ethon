module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making HEAD requests.
        class Head < Action
          def set_nothing(easy)
            easy.nobody = true
            easy.url = url
          end

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
