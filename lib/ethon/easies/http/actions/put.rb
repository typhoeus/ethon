module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making PUT requests.
        class Put < Action

          # Set things up when form is provided.
          # Deals with multipart forms.
          #
          # @example Setup.
          #   put.set_form(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_form(easy)
            easy.url ||= url
            easy.upload = true
            form.escape = true
            easy.infilesize = form.to_s.bytesize
            easy.set_read_callback(form.to_s)
          end

          def set_customs(easy)
            if form.empty?
              easy.upload = true
              easy.infilesize = 0
            end
          end
        end
      end
    end
  end
end
