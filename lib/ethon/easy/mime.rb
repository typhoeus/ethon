# frozen_string_literal: true
module Ethon
  class Easy
    module Mime
      attr_reader :mime

      # Install a MIME structure as the request body.
      #
      # @param [ Ethon::Curl::Mime, nil ] mime The MIME structure.
      #
      # @return [ Ethon::Curl::Mime, nil ] The MIME structure.
      def mime=(mime)
        mime.check_pid! if mime.respond_to?(:check_pid!)
        Curl.set_option(:mimepost, mime, handle)
        @mime = mime
        mime
      end
      alias mimepost= mime=
    end

    include Mime
  end
end
