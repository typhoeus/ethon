module Ethon
  module Easies
    module Http
      module Actions # :nodoc:

        # This class knows everything about making POST requests.
        class Post < Action

          # Set url, postfieldsize and copypostfields.
          #
          # @example Setup.
          #   post.set_nothing(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_nothing(easy)
            easy.url = url
            easy.postfieldsize = 0
            easy.copypostfields = ""
          end

          # Set url with escaped params, postfieldsize and copypostfields.
          #
          # @example Setup.
          #   post.set_params(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_params(easy)
            params.escape = true
            easy.url = "#{url}?#{params.to_s}"
            easy.postfieldsize = 0
            easy.copypostfields = ""
          end

          # Set things up when form is provided.
          # Deals with multipart forms.
          #
          # @example Setup.
          #   post.set_form(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_form(easy)
            easy.url ||= url
            if form.multipart?
              form.escape = false
              form.materialize
              easy.httppost = form.first.read_pointer
            else
              form.escape = true
              easy.copypostfields = form.to_s
              easy.postfieldsize = easy.copypostfields.bytesize
            end
          end
        end
      end
    end
  end
end
