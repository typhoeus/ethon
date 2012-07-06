module Ethon
  module Curls

    # This module contains the available proxy types.
    module ProxyTypes

      # Return proxy types.
      #
      # @example Return proxy types.
      #   Ethon::Curl.proxy_types
      #
      # @return [ Hash ] The proxy_types.
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
