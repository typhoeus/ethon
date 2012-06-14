module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making PUT requests.
        class Put < Action

          # Set things up when neither params nor body is provided.
          #
          # @example Setup.
          #   put.set_nothing(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_nothing(easy)
            easy.url = url
            easy.upload = true
            easy.infilesize = 0
          end

          # Set things up when params is provided.
          #
          # @example Setup.
          #   put.set_params(easy)
          #
          # @param [ Easy ] easy The easy to setup.
          def set_params(easy)
            params.escape = true
            easy.url = "#{url}?#{params.to_s}"
            easy.upload = true
            easy.infilesize = 0
          end

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
        end
      end
    end
  end
end
