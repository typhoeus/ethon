module Ethon
  module Easies
    module Http
      module Postable
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
