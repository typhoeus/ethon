# frozen_string_literal: true
module Ethon
  class Easy
    module Mime
      attr_reader :mime

      # Install a MIME structure as the request body.
      #
      # @param [ Ethon::Curl::Mime, nil ] mime The MIME structure.
      #
      # @raise [ TypeError ] If mime is not a MIME structure.
      #
      # @return [ Ethon::Curl::Mime, nil ] The MIME structure.
      def mime=(mime)
        unless mime.nil? || mime.is_a?(Curl::Mime)
          raise TypeError, "expected an Ethon::Curl::Mime, got #{mime.class}"
        end

        mime.check_pid! if mime
        Curl.set_option(:mimepost, mime, handle)
        @mime = mime
        mime
      end
      alias mimepost= mime=
    end

    include Mime
  end
end
