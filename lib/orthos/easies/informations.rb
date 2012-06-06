module Orthos
  module Easies
    module Informations
      def auth_methods
        Curl.get_info_long(:httpauth_avail, handle)
      end

      def total_time_taken
        Curl.get_info_double(:total_time, handle)
      end

      def start_transfer_time
        Curl.get_info_double(:starttransfer_time, handle)
      end

      def app_connect_time
        Curl.get_info_double(:appconnect_time, handle)
      end

      def pretransfer_time
        Curl.get_info_double(:pretransfer_time, handle)
      end

      def connect_time
        Curl.get_info_double(:connect_time, handle)
      end

      def name_lookup_time
        Curl.get_info_double(:namelookup_time, handle)
      end

      def effective_url
        Curl.get_info_string(:effective_url, handle)
      end

      def primary_ip
        Curl.get_info_string(:primary_ip, handle)
      end

      def response_code
        Curl.get_info_long(:response_code, handle)
      end

      def redirect_count
        Curl.get_info_long(:redirect_count, handle)
      end

      def supports_zlib?
        !!(Curl.version.match(/zlib/))
      end
    end
  end
end
