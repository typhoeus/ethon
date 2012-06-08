module Ethon
  module Easies

    # This module contains the methods to return informations
    # from the easy handle.
    module Informations

      # Return the available http auth methods.
      #
      # @example Return the auth methods.
      #   easy.auth_methods
      #
      # @return [ String ] The auth methods.
      def auth_methods
        Curl.get_info_long(:httpauth_avail, handle)
      end

      # Return the total time in seconds for the previous
      # transfer, including name resolving, TCP connect etc.
      #
      # @example Return the total time.
      #   easy.total_time_taken
      #
      # @return [ Float ] The total time.
      def total_time_taken
        Curl.get_info_double(:total_time, handle)
      end

      # Return the time, in seconds, it took from the start
      # until the first byte is received by libcurl. This
      # includes pretransfer time and also the time the
      # server needs to calculate the result.
      #
      # @example Return the start_transfer_time.
      #   easy.start_transfer_time
      #
      # @return [ Float ] The start transfer time.
      def start_transfer_time
        Curl.get_info_double(:starttransfer_time, handle)
      end

      # Return the time, in seconds, it took from the start
      # until the SSL/SSH connect/handshake to the remote
      # host was completed. This time is most often very near
      # to the pre transfer time, except for cases such as HTTP
      # pippelining where the pretransfer time can be delayed
      # due to waits in line for the pipeline and more.
      #
      # @example Return the app connect time.
      #   easy.app_connect_time
      #
      # @result [ Float ] The app connect time.
      def app_connect_time
        Curl.get_info_double(:appconnect_time, handle)
      end

      # Return the time, in seconds, it took from the start
      # until the file transfer is just about to begin. This
      # includes all pre-transfer commands and negotiations
      # that are specific to the particular protocol(s) involved.
      # It does not involve the sending of the protocol-
      # specific request that triggers a transfer.
      #
      # @example Return the pre transfer time.
      #   easy.pretransfer_time
      #
      # @result [ Float ] The pre transfer time.
      def pretransfer_time
        Curl.get_info_double(:pretransfer_time, handle)
      end

      # Return the time, in seconds, it took from the start
      # until the connect to the remote host (or proxy) was completed.
      #
      # @example Return the connect time.
      #   easy.connect_time
      #
      # @return [ Float ] The connect time.
      def connect_time
        Curl.get_info_double(:connect_time, handle)
      end

      # Return the time, in seconds, it took from the
      # start until the name resolving was completed.
      #
      # @example Return the name lookup time.
      #   easy.name_lookup_time
      #
      # @return [ Float ] The name lookup time.
      def name_lookup_time
        Curl.get_info_double(:namelookup_time, handle)
      end

      # Return the last used effective url.
      #
      # @example Return the effective url.
      #   easy.effective_url
      #
      # @return [ String ] The effective url.
      def effective_url
        Curl.get_info_string(:effective_url, handle)
      end

      # Return the string holding the IP address of the most recent
      # connection done with this curl handle. This string
      # may be IPv6 if that's enabled.
      #
      # @example Return the primary ip.
      #   easy.primary_ip
      #
      # @return [ String ] The primary ip.
      def primary_ip
        Curl.get_info_string(:primary_ip, handle)
      end

      # Return the last received HTTP, FTP or SMTP response code.
      # The value will be zero if no server response code has
      # been received. Note that a proxy's CONNECT response should
      # be read with http_connect_code and not this.
      #
      # @example Return the response code.
      #   easy.response_code
      #
      # @return [ Integer ] The response code.
      def response_code
        Curl.get_info_long(:response_code, handle)
      end

      # Return the total number of redirections that were
      # actually followed
      #
      # @example Return the redirect count.
      #   easy.redirect_count
      #
      # @return [ Integer ] The redirect count.
      def redirect_count
        Curl.get_info_long(:redirect_count, handle)
      end

      # Returns this curl version supports zlib.
      #
      # @example Return wether zlib is supported.
      #   easy.supports_zlib?
      #
      # @return [ Boolean ] True if supported, else false.
      def supports_zlib?
        !!(Curl.version.match(/zlib/))
      end
    end
  end
end
