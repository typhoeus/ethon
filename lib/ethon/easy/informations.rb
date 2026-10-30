# frozen_string_literal: true
module Ethon
  class Easy

    # This module contains the methods to return informations
    # from the easy handle. See https://curl.se/libcurl/c/curl_easy_getinfo.html
    # for more information.
    module Informations

      # Holds available informations and their type, which is needed to
      # request the informations from libcurl.
      AVAILABLE_INFORMATIONS = {
        # The _T variants use curl_off_t and do not lose precision for large
        # values or long-running transfers.
        :size_upload_t => :off_t,
        :size_download_t => :off_t,
        :speed_download_t => :off_t,
        :speed_upload_t => :off_t,
        :filetime_t => :off_t,
        :content_length_download_t => :off_t,
        :content_length_upload_t => :off_t,
        :total_time_t => :off_t,
        :namelookup_time_t => :off_t,
        :connect_time_t => :off_t,
        :pretransfer_time_t => :off_t,
        :starttransfer_time_t => :off_t,
        :redirect_time_t => :off_t,
        :appconnect_time_t => :off_t,
        :retry_after => :off_t,
        :xfer_id => :off_t,
        :conn_id => :off_t,
        :queue_time_t => :off_t,
        :posttransfer_time_t => :off_t,
        :earlydata_sent_t => :off_t,
        :size_delivered => :off_t,
        :filetime => :long,

        # Connection/request metadata.
        :http_version => :long,
        :httpauth_used => :long,
        :proxyauth_used => :long,
        :proxy_ssl_verifyresult => :long,
        # Result of the SSL peer certificate verification. Zero means the
        # certificate was verified successfully. (Added in 7.19.0)
        :ssl_verifyresult => :long,
        :proxy_error => :long,
        :used_proxy => :long,
        :local_port => :long,
        :num_connects => :long,
        :lastsocket => :long,
        :os_errno => :long,
        :http_connectcode => :long,
        :proxyauth_avail => :long,
        :condition_unmet => :long,
        :header_size => :long,
        :rtsp_client_cseq => :long,
        :rtsp_server_cseq => :long,
        :rtsp_cseq_recv => :long,
        :scheme => :string,
        :effective_method => :string,
        :referer => :string,
        :cainfo => :string,
        :capath => :string,
        :content_type => :string,
        :ftp_entry_path => :string,
        :rtsp_session_id => :string,
        :activesocket => :socket,
        :tls_ssl_ptr => :ptr,

        # Return the available HTTP auth methods.
        :httpauth_avail => :long,

        # Return the total time in seconds for the previous
        # transfer, including name resolution, TCP connection, etc.
        :total_time => :double,

        # Return the time, in seconds, it took from the start
        # until the first byte was received by libcurl. This
        # includes pre-transfer time and also the time the
        # server needs to calculate the result.
        :starttransfer_time => :double,

        # Return the time, in seconds, it took from the start
        # until the SSL/SSH connect/handshake to the remote
        # host was completed. This time is most often very near
        # to the pre-transfer time, except for cases such as HTTP
        # pipelining where the pre-transfer time can be delayed
        # due to waits in line for the pipeline and more.
        :appconnect_time => :double,

        # Return the time, in seconds, it took from the start
        # until the file transfer was just about to begin. This
        # includes all pre-transfer commands and negotiations
        # that are specific to the particular protocol(s) involved.
        # It does not involve the sending of the protocol-
        # specific request that triggers a transfer.
        :pretransfer_time => :double,

        # Return the time, in seconds, it took from the start
        # until the connect to the remote host (or proxy) was completed.
        :connect_time => :double,

        # Return the time, in seconds, it took from the
        # start until the name resolution was completed.
        :namelookup_time => :double,

        # Return the time, in seconds, it took for all redirection steps
        # include name lookup, connect, pretransfer and transfer before the
        # final transaction was started. time_redirect shows the complete
        # execution time for multiple redirections. (Added in 7.12.3)
        :redirect_time => :double,

        # Return the last used effective url.
        :effective_url => :string,

        # Return the string holding the IP address of the most recent
        # connection done with this curl handle. This string
        # may be IPv6 if that's enabled.
        :primary_ip => :string,

        # Return the local IP address of the most recent connection.
        :local_ip => :string,

        # Return the destination port of the most recent connection.
        :primary_port => :long,

        # Return the last received HTTP, FTP or SMTP response code.
        # The value will be zero if no server response code has
        # been received. Note that a proxy's CONNECT response should
        # be read with http_connect_code and not this.
        :response_code => :long,

        :request_size => :long,

        # Return the total number of redirections that were
        # actually followed.
        :redirect_count => :long,

        # URL a redirect would take you to, had you enabled redirects (Added in 7.18.2)
        :redirect_url => :string,

        # Return the bytes, the total amount of bytes that were uploaded
        :size_upload => :double,

        # Return the bytes, the total amount of bytes that were downloaded.
        # The amount is only for the latest transfer and will be reset again
        # for each new transfer. This counts actual payload data, what's
        # also commonly called body. All meta and header data are excluded
        # and will not be counted in this number.
        :size_download => :double,

        # Return the content length of the download or upload.
        :content_length_download => :double,
        :content_length_upload => :double,

        # Return the bytes/second, the average upload speed that curl
        # measured for the complete upload
        :speed_upload => :double,

        # Return the bytes/second, the average download speed that curl
        # measured for the complete download
        :speed_download => :double
      }

      LIST_INFORMATIONS = [:ssl_engines, :cookielist].freeze

      AVAILABLE_INFORMATIONS.each do |name, type|
        eval %Q|def #{name}; Curl.send(:get_info_#{type}, :#{name}, handle); end|
      end

      LIST_INFORMATIONS.each do |name|
        define_method(name) { Curl.get_info_slist(name, handle) }
      end

      def certinfo
        Curl.get_info_certinfo(:certinfo, handle)
      end

      # Returns true if this curl version supports zlib.
      #
      # @example Return wether zlib is supported.
      #   easy.supports_zlib?
      #
      # @return [ Boolean ] True if supported, else false.
      # @deprecated Please use the static version instead
      def supports_zlib?
        Kernel.warn("Ethon: Easy#supports_zlib? is deprecated and will be removed, please use Easy.supports_zlib? instead.")
        Easy.supports_zlib?
      end

    end
  end
end
