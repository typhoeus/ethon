module Ethon
  module Curls
    module SslVersions
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
