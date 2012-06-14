module Ethon
  module Easies
    module Http
      module Actions # :nodoc:

        # This class knows everything about making POST requests.
        class Post < Action

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

          def set_customs(easy)
            if form.empty?
              easy.postfieldsize = 0
              easy.copypostfields = ""
            end
          end
        end
      end
    end
  end
end
