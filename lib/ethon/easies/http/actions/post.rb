module Ethon
  module Easies
    module Http
      module Actions
        class Post < Action
          def setup(easy)
            set_nothing(easy) if params.empty? && form.empty?
            set_params(easy) unless params.empty?
            set_form(easy) unless form.empty?
          end

          def set_nothing(easy)
            easy.url = url
            easy.postfieldsize = 0
            easy.copypostfields = ""
          end

          def set_params(easy)
            params.escape = true
            easy.url = "#{url}?#{params.to_s}"
            easy.postfieldsize = 0
            easy.copypostfields = ""
          end

          def set_form(easy)
            easy.url = url
            form.escape = false
            form.materialize
            easy.httppost = form.first.read_pointer
          end
        end
      end
    end
  end
end
