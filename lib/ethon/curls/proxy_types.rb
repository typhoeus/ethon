module Ethon
  module Curls
    module ProxyTypes
      def proxy_types
        {
          :http =>           0,
          :http_1_0 =>       1,
          :socks4 =>         4,
          :socks5 =>         5,
          :socks4a =>        6,
          :socks5_hostname =>7
        }
      end
    end
  end
end
