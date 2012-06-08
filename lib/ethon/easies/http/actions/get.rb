module Ethon
  module Easies
    module Http
      module Actions
        class Get < Action
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
