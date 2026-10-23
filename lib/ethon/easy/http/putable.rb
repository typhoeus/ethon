# frozen_string_literal: true
module Ethon
  class Easy
    module Http

      # This module contains logic about setting up a PUT body.
      module Putable
        # Set things up when form is provided.
        # Deals with multipart forms.
        #
        # @example Setup.
        #   put.set_form(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_form(easy)
          easy.url ||= url
          form.params_encoding = params_encoding
          if form.multipart?
            form.escape = false
            if Ethon::Curl.respond_to?(:mime_init)
              easy.multipart_form = nil
              easy.mime = form.mime
            else
              form.materialize
              easy.multipart_form = form
            end
            easy.customrequest = "PUT"
          else
            easy.multipart_form = nil
            easy.mime = nil if Ethon::Curl.respond_to?(:mime_init)
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
