# frozen_string_literal: true
module Ethon
  class Easy
    class Mirror
      attr_reader :options
      alias_method :to_hash, :options

      # Raw pointers cannot be marshaled and point into native state that can
      # go away when the handle is reset. Applications serialize a mirror (for
      # example as a cached Typhoeus response), so leave them on the Easy.
      INFORMATIONS_TO_MIRROR = Informations::AVAILABLE_INFORMATIONS.
          reject { |_, type| type == :ptr }.keys +
          [:return_code, :response_headers, :response_body, :debug_info, :error_message]

      INFORMATIONS_TO_LOG = [:effective_url, :response_code, :return_code, :total_time]

      # Credentials embedded in the URL are not useful in logs and may end up
      # in a log aggregator. Keep the scheme and host so the line is still
      # identifiable, but replace the userinfo.
      URL_CREDENTIALS = %r{\A([a-z][a-z0-9+.-]*://)[^/?#@]*@}i

      def self.from_easy(easy)
        options = {}
        INFORMATIONS_TO_MIRROR.each do |info|
          options[info] = easy.send(info)
        end
        new(options)
      end

      def initialize(options = {})
        @options = options
      end

      def log_informations
        Hash[*INFORMATIONS_TO_LOG.map do |info|
          value = options[info]
          if info == :effective_url && value.is_a?(String)
            value = value.sub(URL_CREDENTIALS, "\\1[REDACTED]@")
          end
          [info, value]
        end.flatten]
      end

      INFORMATIONS_TO_MIRROR.each do |info|
        define_method(info) { options[info] }
      end
    end
  end
end
