module Ethon
  module Easies
    module Http
      module Actions

        # This class knows everything about making PUT requests.
        class Put < Action

          # Setup everything what is necessary for a proper
          # PUT request.
          #
          # @example setup.
          #   put.setup(easy)
          #
          # @param [ easy ] easy the easy to setup.
          def setup(easy)
            set_nothing(easy) if params.empty? && form.empty?
            set_params(easy) unless params.empty?
            set_upload(easy) unless form.empty?
          end

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
          def set_upload(easy)
            easy.url ||= url
            easy.upload = true
            easy.infilesize = form.to_s.bytesize
            easy.set_read_callback(form.to_s)
          end
        end
      end
    end
  end
end
