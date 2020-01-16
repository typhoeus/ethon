module Ethon
  class Easy
    class Mirror
      attr_reader :options
      alias_method :to_hash, :options

      INFORMATIONS_TO_MIRROR = []

      def self.mirror_information(info)
        INFORMATIONS_TO_MIRROR << info
        define_method(info) { options[info] }
      end

      Informations::AVAILABLE_INFORMATIONS.keys.each do |info|
        mirror_information(info)
      end

      mirror_information(:return_code)
      mirror_information(:response_headers)
      mirror_information(:response_body)
      mirror_information(:debug_info)

      INFORMATIONS_TO_LOG = [:effective_url, :response_code, :return_code, :total_time]

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
          [info, options[info]]
        end.flatten]
      end
    end
  end
end
