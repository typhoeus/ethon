module Ethon
  module Easies
    module Http
      module Actions
        class Head < Action
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
