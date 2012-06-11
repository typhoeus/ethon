module Ethon
  module Easies
    module Http
      module Actions
        class Put < Action
          def setup(easy)
            set_nothing(easy) if params.empty? && form.empty?
            set_params(easy) unless params.empty?
            set_upload(easy) unless form.empty?
          end

          def set_nothing(easy)
            easy.url = url
            easy.upload = true
            easy.infilesize = 0
          end

          def set_params(easy)
            params.escape = true
            easy.url = "#{url}?#{params.to_s}"
            easy.upload = true
            easy.infilesize = 0
          end

          def set_upload(easy)
          end
        end
      end
    end
  end
end
