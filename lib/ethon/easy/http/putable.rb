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
            form.materialize
            easy.httppost = form.first.read_pointer
            easy.customrequest = 'PUT'
          else
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
