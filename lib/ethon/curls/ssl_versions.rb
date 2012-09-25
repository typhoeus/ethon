module Ethon
  module Curls

    # This module contains the ssl version.
    module SslVersions

      # Return the ssl versions.
      #
      # @example Retur the ssl versions.
      #   Ethon::Curl.ssl_versions
      #
      # @return [ Hash ] The versions.
      def ssl_versions
        {
          :default =>0,
          :tlsv1 =>  1,
          :sslv2 =>  2,
          :sslv3 =>  3
        }
      end
    end
  end
end
