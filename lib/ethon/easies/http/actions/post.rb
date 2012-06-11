module Ethon
  module Easies
    module Http
      module Actions # :nodoc:

        # This class knows everything about making POST requests.
        class Post < Action

          # Setup everything what is necessary for a proper
          # POST request.
          #
          # @example setup.
          #   post.setup(easy)
          #
          # @param [ easy ] easy the easy to setup.
          def setup(easy)
            set_nothing(easy) if params.empty? && form.empty?
            set_params(easy) unless params.empty?
            set_form(easy) unless form.empty?
          end

          # Set things up when neither params nor body is provided.
          #
          # @example Setup.
          #   post.set_nothing(easy)
          #
          # @parms [ Easy ] easy The easy to setup.
          def set_nothing(easy)
            easy.url = url
            easy.postfieldsize = 0
            easy.copypostfields = ""
          end

          # Set things up when params is provided.
          #
          # @example Setup.
          #   post.set_params(easy)
          #
          # @parms [ Easy ] easy The easy to setup.
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
          # @parms [ Easy ] easy The easy to setup.
          def set_form(easy)
            easy.url ||= url
            if form.multipart?
              form.materialize
              easy.httppost = form.first.read_pointer
            else
              easy.copypostfields = form.to_s
              easy.postfieldsize = easy.copypostfields.bytesize
            end
          end
        end
      end
    end
  end
end
