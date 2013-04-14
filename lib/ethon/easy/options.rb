module Ethon
  class Easy

    # This module contains the logic and knowledge about the
    # available options on easy.
    module Options

      attr_reader :url

      # Sets the contents of the Accept-Encoding: header sent in a HTTP
      # request, and enables decoding of a response when a
      # Content-Encoding: header is received. Three encodings are
      # supported: identity, which does nothing, deflate which requests
      # the server to compress its response using the zlib algorithm,
      # and gzip which requests the gzip algorithm. If a zero-length
      # string is set, then an Accept-Encoding: header containing all
      # supported encodings is sent.
      # This is a request, not an order; the server may or may not do it.
      # This option must be set (to any non-NULL value) or else any
      # unsolicited encoding done by the server is ignored. See the
      # special file lib/README.encoding for details.
      # (This option was called CURLOPT_ENCODING before 7.21.6)
      #
      # @example Set accept_encoding option.
      #   easy.accept_encoding = "gzip"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def accept_encoding=(value)
        Curl.set_option(:accept_encoding, value_for(value, :string), handle)
      end

      # Pass a string to a zero-terminated string naming a file holding one
      # or more certificates with which to verify the peer. This makes sense
      # only when used in combination with the CURLOPT_SSL_VERIFYPEER option.
      # If CURLOPT_SSL_VERIFYPEER is zero, CURLOPT_CAINFO need not even
      # indicate an accessible file. This option is by default set to the
      # system path where libcurl's cacert bundle is assumed to be stored,
      # as established at build time. When built against NSS, this is the
      # directory that the NSS certificate database resides in.
      #
      # @example Set cainfo option.
      #   easy.cainfo = "/path/to/file"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def cainfo=(value)
        Curl.set_option(:cainfo, value_for(value, :string), handle)
      end

      # Pass a string to a zero-terminated string naming a directory holding
      # multiple CA certificates with which to verify the peer. If libcurl is
      # built against OpenSSL, the certificate directory must be prepared using
      # the openssl c_rehash utility. This makes sense only when used in
      # combination with the CURLOPT_SSL_VERIFYPEER option. If
      # CURLOPT_SSL_VERIFYPEER is zero, CURLOPT_CAPATH need not even indicate
      # an accessible path. The CURLOPT_CAPATH function apparently does not
      # work in Windows due to some limitation in openssl. This option is
      # OpenSSL-specific and does nothing if libcurl is built to use GnuTLS.
      # NSS-powered libcurl provides the option only for backward
      # compatibility.
      #
      # @example Set capath option.
      #   easy.capath = "/path/to/file"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def capath=(value)
        Curl.set_option(:capath, value_for(value, :string), handle)
      end

      # Pass a long. It should contain the maximum time in seconds that you
      # allow the connection to the server to take. This only limits the
      # connection phase, once it has connected, this option is of no more
      # use. Set to zero to switch to the default built-in connection timeout
      # \- 300 seconds. See also the CURLOPT_TIMEOUT option.
      # In Unix-like systems, this might cause signals to be used unless
      # CURLOPT_NOSIGNAL is set.
      #
      # @example Set connecttimeout option.
      #   easy.connecttimeout = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def connecttimeout=(value)
        Curl.set_option(:connecttimeout, value_for(value, :int), handle)
      end

      # Like CURLOPT_CONNECTTIMEOUT but takes the number of milliseconds
      # instead. If libcurl is built to use the standard system name
      # resolver, that portion of the connect will still use full-second
      # resolution for timeouts with a minimum timeout allowed of one second.
      # (Added in 7.16.2)
      #
      # @example Set connecttimeout_ms option.
      #   easy.connecttimeout_ms = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def connecttimeout_ms=(value)
        Curl.set_option(:connecttimeout_ms, value_for(value, :int), handle)
      end

      # Sets the cookie value
      #
      # If you want to read/write the cookie from a file,
      # see cookiefile= and cookiejar=
      #
      # @example Set the cookie option
      #   easy.cookie = "cookie-value"
      #
      # @param [ String ] value The cookie value
      #
      # @return [ void ]
      def cookie=(value)
        Curl.set_option(:cookie, value_for(value, :string), handle)
      end

      # Sets the cookie jar file
      # The file will only be used to write the cookie value
      # If you want to read the cookie from a file, see cookiefile=
      #
      # If the file does not exist, it will try to create it
      #
      # @example Set cookiejar option
      #   easy.cookiejar = "/path/to/file"
      #
      # @param [ String ] file The path to the file
      #
      # @return [ void ]
      def cookiejar=(file)
        Curl.set_option(:cookiejar, value_for(file, :string), handle)
      end

      # Sets the cookie file
      # The file will only be used to read the cookie value
      # If you want to set the cookie in a file, see cookiejar=
      #
      # @example Set cookiefile option
      #   easy.cookiefile = "/path/to/file"
      #
      # @param [ String ] file The path to the file
      #
      # @return [ void ]
      def cookiefile=(file)
        Curl.set_option(:cookiefile, value_for(file, :string), handle)
      end

      # Pass a string as parameter, which should be the full data to post in
      # a HTTP POST operation. It behaves as the CURLOPT_POSTFIELDS option,
      # but the original data are copied by the library, allowing the
      # application to overwrite the original data after setting this option.
      # Because data are copied, care must be taken when using this option in
      # conjunction with CURLOPT_POSTFIELDSIZE or
      # CURLOPT_POSTFIELDSIZE_LARGE: If the size has not been set prior to
      # CURLOPT_COPYPOSTFIELDS, the data are assumed to be a NUL-terminated
      # string; else the stored size informs the library about the data byte
      # count to copy. In any case, the size must not be changed after
      # CURLOPT_COPYPOSTFIELDS, unless another CURLOPT_POSTFIELDS or
      # CURLOPT_COPYPOSTFIELDS option is issued. (Added in 7.17.1)
      #
      # @example Set copypostfields option.
      #   easy.copypostfields = "PATCH"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def copypostfields=(value)
        Curl.set_option(:copypostfields, value_for(value, :string), handle)
      end

      # Pass a pointer to a zero-terminated string as parameter. It can be
      # used to specify the request instead of GET or HEAD when performing
      # HTTP based requests, instead of LIST and NLST when performing FTP
      # directory listings and instead of LIST and RETR when issuing POP3
      # based commands. This is particularly useful, for example, for
      # performing a HTTP DELETE request or a POP3 DELE command.
      # Please don't perform this at will, on HTTP based requests, by making
      # sure your server supports the command you are sending first.
      # When you change the request method by setting CURLOPT_CUSTOMREQUEST
      # to something, you don't actually change how libcurl behaves or acts
      # in regards to the particular request method, it will only change the
      # actual string sent in the request.
      # For example:
      # With the HTTP protocol, when you tell libcurl to do a HEAD request,
      # but then specify a GET though a custom request libcurl will still act
      # as if it sent a HEAD. To switch to a proper HEAD use CURLOPT_NOBODY,
      # to switch to a proper POST use CURLOPT_POST or CURLOPT_POSTFIELDS and
      # to switch to a proper GET use CURLOPT_HTTPGET.
      # With the POP3 protocol when you tell libcurl to use a custom request
      # it will behave like a LIST or RETR command was sent where it expects
      # data to be returned by the server. As such CURLOPT_NOBODY should be
      # used when specifying commands such as DELE and NOOP for example.
      # Restore to the internal default by setting this to NULL.
      # Many people have wrongly used this option to replace the entire
      # request with their own, including multiple headers and POST contents.
      # While that might work in many cases, it will cause libcurl to send
      # invalid requests and it could possibly confuse the remote server
      # badly. Use CURLOPT_POST and CURLOPT_POSTFIELDS to set POST data. Use
      # CURLOPT_HTTPHEADER to replace or extend the set of headers sent by
      # libcurl. Use CURLOPT_HTTP_VERSION to change HTTP version.
      # (Support for POP3 added in 7.26.0)
      #
      # @example Set customrequest option.
      #   easy.customrequest = "PATCH"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def customrequest=(value)
        Curl.set_option(:customrequest, value_for(value, :string), handle)
      end

      # Pass a long, this sets the timeout in seconds. Name resolutions will be
      # kept in memory for this number of seconds. Set to zero to completely
      # disable caching, or set to -1 to make the cached entries remain
      # forever. By default, libcurl caches this info for 60 seconds.
      # The name resolve functions of various libc implementations don't
      # re-read name server information unless explicitly told so (for
      # example, by calling res_init(3)). This may cause libcurl to keep
      # using the older server even if DHCP has updated the server info, and
      # this may look like a DNS cache issue to the casual libcurl-app user.
      #
      # @example Set dns_cache_timeout option.
      #   easy.dns_cache_timeout = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def dns_cache_timeout=(value)
        Curl.set_option(:dns_cache_timeout, value_for(value, :int), handle)
      end

      # A parameter set to 1 tells the library to follow any Location: header
      # that the server sends as part of a HTTP header.
      # This means that the library will re-send the same request on the new
      # location and follow new Location: headers all the way until no more
      # such headers are returned. CURLOPT_MAXREDIRS can be used to limit the
      # number of redirects libcurl will follow.
      # Since 7.19.4, libcurl can limit what protocols it will automatically
      # follow. The accepted protocols are set with CURLOPT_REDIR_PROTOCOLS
      # and it excludes the FILE protocol by default.
      #
      # @example Set followlocation option.
      #   easy.followlocation = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def followlocation=(value)
        Curl.set_option(:followlocation, value_for(value, :bool), handle)
      end

      # Pass a long. Set to 1 to make the next transfer explicitly close the
      # connection when done. Normally, libcurl keeps all connections alive
      # when done with one transfer in case a succeeding one follows that can
      # re-use them. This option should be used with caution and only if you
      # understand what it does. Set to 0 to have libcurl keep the connection
      # open for possible later re-use (default behavior).
      #
      # @example Set forbid_reuse option.
      #   easy.forbid_reuse = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def forbid_reuse=(value)
        Curl.set_option(:forbid_reuse, value_for(value, :bool), handle)
      end

      # Pass a long as parameter, which is set to a bitmask, to tell libcurl
      # which authentication method(s) you want it to use. The available bits
      # are listed below. If more than one bit is set, libcurl will first
      # query the site to see which authentication methods it supports and
      # then pick the best one you allow it to use. For some methods, this
      # will induce an extra network round-trip. Set the actual name and
      # password with the CURLOPT_USERPWD option or with the CURLOPT_USERNAME
      # and the CURLOPT_PASSWORD options. (Added in 7.10.6)
      #
      # @example Set httpauth option.
      #   easy.httpauth = :basic
      #
      # @param [ $type_doc ] value The value to set.
      #
      # @return [ void ]
      def httpauth=(value)
        Curl.set_option(:httpauth, value_for(value, :enum, :httpauth), handle)
      end

      # Pass a long. If the long is 1, this forces the HTTP request to get
      # back to GET. Usable if a POST, HEAD, PUT, or a custom request has
      # been used previously using the same curl handle.
      # When setting CURLOPT_HTTPGET to 1, it will automatically set
      # CURLOPT_NOBODY to 0 (since 7.14.1).
      #
      # @example Set httpget option.
      #   easy.httpget = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def httpget=(value)
        Curl.set_option(:httpget, value_for(value, :bool), handle)
      end

      # Tells libcurl you want a multipart/formdata HTTP POST to be made and
      # you instruct what data to pass on to the server. Pass a pointer to a
      # linked list of curl_httppost structs as parameter. The easiest way to
      # create such a list, is to use curl_formadd(3) as documented. The data
      # in this list must remain intact until you close this curl handle
      # again with curl_easy_cleanup(3).
      # Using POST with HTTP 1.1 implies the use of a "Expect: 100-continue"
      # header. You can disable this header with CURLOPT_HTTPHEADER as usual.
      # When setting CURLOPT_HTTPPOST, it will automatically set
      # CURLOPT_NOBODY to 0 (since 7.14.1).
      #
      # @example Set httppost option.
      #   easy.httppost = value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def httppost=(value)
        Curl.set_option(:httppost, value_for(value, :string), handle)
      end

      # Pass a long, set to one of the values described below. They force
      # libcurl to use the specific HTTP versions. This is not sensible
      # to do unless you have a good reason.
      #
      # Options:
      #
      #   * :none: We don't care about what version the library uses.
      #     libcurl will use whatever it thinks fit.
      #   * :httpv1_0: Enforce HTTP 1.0 requests.
      #   * :httpv1_1: Enforce HTTP 1.1 requests.
      #
      # @example Set http_version option.
      #   easy.http_version = :httpv1_0
      #
      # @param [ Symbol ] value The value to set.
      #
      # @return [ void ]
      def http_version=(value)
        Curl.set_option(:http_version, value_for(value, :enum, :http_version), handle)
      end

      # When uploading a file to a remote site, this option should be used to
      # tell libcurl what the expected size of the infile is. This value
      # should be passed as a long. See also CURLOPT_INFILESIZE_LARGE.
      # For uploading using SCP, this option or CURLOPT_INFILESIZE_LARGE is
      # mandatory.
      # When sending emails using SMTP, this command can be used to specify
      # the optional SIZE parameter for the MAIL FROM command. (Added in
      # 7.23.0)
      # This option does not limit how much data libcurl will actually send,
      # as that is controlled entirely by what the read callback returns.
      #
      # @example Set infilesize option.
      #   easy.infilesize = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def infilesize=(value)
        Curl.set_option(:infilesize, value_for(value, :int), handle)
      end

      # Pass a string as parameter. This sets the interface name to use as
      # outgoing network interface. The name can be an interface name, an IP
      # address, or a host name.
      # Starting with 7.24.0: If the parameter starts with "if!" then it is
      # treated as only as interface name and no attempt will ever be named
      # to do treat it as an IP address or to do name resolution on it. If
      # the parameter starts with "host!" it is treated as either an IP
      # address or a hostname. Hostnames are resolved synchronously. Using
      # the if! format is highly recommended when using the multi interfaces
      # to avoid allowing the code to block. If "if!" is specified but the
      # parameter does not match an existing interface,
      # CURLE_INTERFACE_FAILED is returned.
      #
      # @example Set interface option.
      #   easy.interface = "eth0"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def interface=(value)
        Curl.set_option(:interface, value_for(value, :string), handle)
      end

      # Pass a pointer to a zero terminated string as parameter. It will be
      # used as the password required to use the CURLOPT_SSLKEY or
      # CURLOPT_SSH_PRIVATE_KEYFILE private key. You never needed a pass
      # phrase to load a certificate but you need one to load your private key.
      # (This option was known as CURLOPT_SSLKEYPASSWD up to 7.16.4 and
      # CURLOPT_SSLCERTPASSWD up to 7.9.2)
      #
      # @example Set keypasswd option.
      #   easy.keypasswd = "password"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def keypasswd=(value)
        Curl.set_option(:keypasswd, value_for(value, :string), handle)
      end

      # Pass a long. The set number will be the redirection limit. If that
      # many redirections have been followed, the next redirect will cause an
      # error (CURLE_TOO_MANY_REDIRECTS). This option only makes sense if the
      # CURLOPT_FOLLOWLOCATION is used at the same time. Added in 7.15.1:
      # Setting the limit to 0 will make libcurl refuse any redirect. Set it
      # to -1 for an infinite number of redirects (which is the default)
      #
      # @example Set maxredirs option.
      #   easy.maxredirs = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def maxredirs=(value)
        Curl.set_option(:maxredirs, value_for(value, :int), handle)
      end

      # Pass a curl_off_t as parameter. If an upload exceeds this speed
      # (counted in bytes per second) on cumulative average during the
      # transfer, the transfer will pause to keep the average rate less than or
      # equal to the parameter value. Defaults to unlimited speed. (Added in
      # 7.15.5)
      #
      # @example Set max_send_speed_large option.
      #   easy.max_send_speed_large = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def max_send_speed_large=(value)
        Curl.set_option(:max_send_speed_large, value_for(value, :int), handle)
      end

      # Pass a curl_off_t as parameter. If a download exceeds this speed
      # (counted in bytes per second) on cumulative average during the
      # transfer, the transfer will pause to keep the average rate less than or
      # equal to the parameter value. Defaults to unlimited speed. (Added in
      # 7.15.5)
      #
      # @example Set max_recv_speed_large option.
      #   easy.max_recv_speed_large = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def max_recv_speed_large=(value)
        Curl.set_option(:max_recv_speed_large, value_for(value, :int), handle)
      end

      # A parameter set to 1 tells the library to not include the body-part
      # in the output. This is only relevant for protocols that have separate
      # header and body parts. On HTTP(S) servers, this will make libcurl do
      # a HEAD request.
      # To change request to GET, you should use CURLOPT_HTTPGET. Change
      # request to POST with CURLOPT_POST etc.
      #
      # @example Set nobody option.
      #   easy.nobody = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def nobody=(value)
        Curl.set_option(:nobody, value_for(value, :bool), handle)
      end

      # Pass a long. If it is 1, libcurl will not use any functions that
      # install signal handlers or any functions that cause signals to be
      # sent to the process. This option is mainly here to allow
      # multi-threaded unix applications to still set/use all timeout options
      # etc, without risking getting signals. (Added in 7.10)
      # If this option is set and libcurl has been built with the standard
      # name resolver, timeouts will not occur while the name resolve takes
      # place. Consider building libcurl with c-ares support to enable
      # asynchronous DNS lookups, which enables nice timeouts for name
      # resolves without signals.
      # Setting CURLOPT_NOSIGNAL to 1 makes libcurl NOT ask the system to
      # ignore SIGPIPE signals, which otherwise are sent by the system when
      # trying to send data to a socket which is closed in the other end.
      # libcurl makes an effort to never cause such SIGPIPEs to trigger, but
      # some operating systems have no way to avoid them and even on those
      # that have there are some corner cases when they may still happen,
      # contrary to our desire. In addition, using CURLAUTH_NTLM_WB
      # authentication could cause a SIGCHLD signal to be raised.
      #
      # @example Set nosignal option.
      #   easy.nosignal = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def nosignal=(value)
        Curl.set_option(:nosignal, value_for(value, :bool), handle)
      end

      # If you want to post data to the server without letting libcurl do a
      # strlen() to measure the data size, this option must be used. When
      # this option is used you can post fully binary data, which otherwise
      # is likely to fail. If this size is set to -1, the library will use
      # strlen() to get the size.
      #
      # @example Set postfieldsize option.
      #   easy.postfieldsize = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def postfieldsize=(value)
        Curl.set_option(:postfieldsize, value_for(value, :int), handle)
      end

      # Pass a bitmask to control how libcurl acts on redirects after
      # POSTs that get a 301, 302 or 303 response back. A parameter
      # with bit 0 set (value CURL_REDIR_POST_301) tells the library
      # to respect RFC 2616/10.3.2 and not convert POST requests into
      # GET requests when following a 301 redirection. Setting bit 1
      # (value CURL_REDIR_POST_302) makes libcurl maintain the request
      # method after a 302 redirect whilst setting bit 2 (value
      # CURL_REDIR_POST_303) makes libcurl maintain the request method
      # after a 303 redirect. The value CURL_REDIR_POST_ALL is a
      # convenience define that sets all three bits.
      #
      # The non-RFC behaviour is ubiquitous in web browsers, so the
      # library does the conversion by default to maintain
      # consistency. However, a server may require a POST to remain a
      # POST after such a redirection. This option is meaningful only
      # when setting CURLOPT_FOLLOWLOCATION. (Added in 7.17.1) (This
      # option was known as CURLOPT_POST301 up to 7.19.0 as it only
      # supported the 301 then)
      #
      # @example Set postredir option.
      #   easy.postredir = :post_all
      #
      # @param [ Symbol ] value The value to set.
      #
      # @return [ void ]
      def postredir=(value)
        Curl.set_option(:postredir, value_for(value, :enum, :postredir), handle)
      end

      # Pass a long that holds a bitmask of CURLPROTO_* defines. If used, this
      # bitmask limits what protocols libcurl may use in the transfer. This
      # allows you to have a libcurl built to support a wide range of protocols
      # but still limit specific transfers to only be allowed to use a subset
      # of them. By default libcurl will accept all protocols it supports. See
      # also CURLOPT_REDIR_PROTOCOLS. (Added in 7.19.4)
      #
      # @example Set protocols option.
      #   easy.protocols = :http
      #
      # @param [ Symbol ] value The value or array of values to set.
      #
      # @return [ void ]
      def protocols=(value)
        Curl.set_option(:protocols, value_for(value, :enum, :protocols), handle)
      end

      # Pass a long that holds a bitmask of CURLPROTO_* defines. If used, this
      # bitmask limits what protocols libcurl may use in a transfer that it
      # follows to in a redirect when CURLOPT_FOLLOWLOCATION is enabled. This
      # allows you to limit specific transfers to only be allowed to use a
      # subset of protocols in redirections. By default libcurl will allow all
      # protocols except for FILE and SCP. This is a difference compared to
      # pre-7.19.4 versions which unconditionally would follow to all protocols
      # supported. (Added in 7.19.4)
      #
      # @example Set redir_protocols option.
      #   easy.redir_protocols = :http
      #
      # @param [ Symbol ] value The value or array of values to set.
      #
      # @return [ void ]
      def redir_protocols=(value)
        Curl.set_option(:redir_protocols, value_for(value, :enum, :redir_protocols), handle)
      end

      # Set HTTP proxy to use. The parameter should be a string to a zero
      # terminated string holding the host name or dotted IP address. To
      # specify port number in this string, append :[port] to the end of the
      # host name. The proxy string may be prefixed with [protocol]:// since
      # any such prefix will be ignored. The proxy's port number may
      # optionally be specified with the separate option. If not specified,
      # libcurl will default to using port 1080 for proxies.
      # CURLOPT_PROXYPORT.
      # When you tell the library to use a HTTP proxy, libcurl will
      # transparently convert operations to HTTP even if you specify an FTP
      # URL etc. This may have an impact on what other features of the
      # library you can use, such as CURLOPT_QUOTE and similar FTP specifics
      # that don't work unless you tunnel through the HTTP proxy. Such
      # tunneling is activated with CURLOPT_HTTPPROXYTUNNEL.
      # libcurl respects the environment variables http_proxy, ftp_proxy,
      # all_proxy etc, if any of those are set. The CURLOPT_PROXY option does
      # however override any possibly set environment variables.
      # Setting the proxy string to "" (an empty string) will explicitly
      # disable the use of a proxy, even if there is an environment variable
      # set for it.
      # Since 7.14.1, the proxy host string given in environment variables
      # can be specified the exact same way as the proxy can be set with
      # CURLOPT_PROXY, include protocol prefix (http://) and embedded user +
      # password.
      # Since 7.21.7, the proxy string may be specified with a protocol://
      # prefix to specify alternative proxy protocols. Use socks4://,
      # socks4a://, socks5:// or socks5h:// (the last one to enable socks5
      # and asking the proxy to do the resolving, also known as
      # CURLPROXY_SOCKS5_HOSTNAME type) to request the specific SOCKS version
      # to be used. No protocol specified, http:// and all others will be
      # treated as HTTP proxies.
      #
      # @example Set proxy option.
      #   easy.proxy = "socks5://27.0.0.1:9050"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def proxy=(value)
        Curl.set_option(:proxy, value_for(value, :string), handle)
      end

      # Pass a long as parameter, which is set to a bitmask, to tell libcurl
      # which authentication method(s) you want it to use for your proxy
      # authentication. If more than one bit is set, libcurl will first query
      # the site to see what authentication methods it supports and then pick
      # the best one you allow it to use. For some methods, this will induce
      # an extra network round-trip. Set the actual name and password with
      # the CURLOPT_PROXYUSERPWD option. The bitmask can be constructed by
      # or'ing together the bits listed above for the CURLOPT_HTTPAUTH
      # option. As of this writing, only Basic, Digest and NTLM work. (Added
      # in 7.10.7)
      #
      # @example Set proxyauth option.
      #   easy.proxyauth = value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def proxyauth=(value)
        Curl.set_option(:proxyauth, value_for(value, :string), handle)
      end

      # Pass a long with this option to set the proxy port to connect to
      # unless it is specified in the proxy string CURLOPT_PROXY.
      #
      # @example Set proxyport option.
      #   easy.proxyport = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def proxyport=(value)
        Curl.set_option(:proxyport, value_for(value, :int), handle)
      end

      # Pass a long with this option to set type of the proxy. Available
      # options for this are CURLPROXY_HTTP, CURLPROXY_HTTP_1_0 (added in
      # 7.19.4), CURLPROXY_SOCKS4 (added in 7.10), CURLPROXY_SOCKS5,
      # CURLPROXY_SOCKS4A (added in 7.18.0) and CURLPROXY_SOCKS5_HOSTNAME
      # (added in 7.18.0). The HTTP type is default. (Added in 7.10)
      # If you set CURLOPT_PROXYTYPE to CURLPROXY_HTTP_1_0, it will only
      # affect how libcurl speaks to a proxy when CONNECT is used. The HTTP
      # version used for "regular" HTTP requests is instead controlled with
      # CURLOPT_HTTP_VERSION.
      #
      # @example Set proxytype option.
      #   easy.proxytype = :socks5
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      #
      # @deprecated Please use the proxy option with protocoll handler.
      def proxytype=(value)
        Ethon.logger.warn(
          "ETHON: Easy#proxytype= is deprecated. "+
          "Please use Easy#proxy= with protocoll handlers."
        )
        Curl.set_option(:proxytype, value_for(value, :string), handle)
      end

      # Pass a string as parameter, which should be [user name]:[password]
      # to use for the connection to the HTTP proxy. Use CURLOPT_PROXYAUTH
      # to decide the authentication method.
      #
      # @example Set proxyuserpwd option.
      #   easy.proxyuserpwd = "user:password"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def proxyuserpwd=(value)
        Curl.set_option(:proxyuserpwd, value_for(value, :string), handle)
      end

      # Data pointer to pass to the file read function. If you use the
      # CURLOPT_READFUNCTION option, this is the pointer you'll get as input.
      # If you don't specify a read callback but instead rely on the default
      # internal read function, this data must be a valid readable FILE *.
      # If you're using libcurl as a win32 DLL, you MUST use a
      # CURLOPT_READFUNCTION if you set this option.
      # This option was also known by the older name CURLOPT_INFILE,
      # the name CURLOPT_READDATA was introduced in 7.9.7.
      #
      # @example Set readdata option.
      #   easy.readdata = value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def readdata=(value)
        Curl.set_option(:readdata, value_for(value, :string), handle)
      end

      # Pass a pointer to a function that matches the following prototype:
      # size_t function( void *ptr, size_t size, size_t nmemb, void
      # *userdata); This function gets called by libcurl as soon as it needs
      # to read data in order to send it to the peer. The data area pointed
      # at by the pointer ptr may be filled with at most size multiplied with
      # nmemb number of bytes. Your function must return the actual number of
      # bytes that you stored in that memory area. Returning 0 will signal
      # end-of-file to the library and cause it to stop the current transfer.
      # If you stop the current transfer by returning 0 "pre-maturely" (i.e
      # before the server expected it, like when you've said you will upload
      # N bytes and you upload less than N bytes), you may experience that
      # the server "hangs" waiting for the rest of the data that won't come.
      # The read callback may return CURL_READFUNC_ABORT to stop the current
      # operation immediately, resulting in a CURLE_ABORTED_BY_CALLBACK error
      # code from the transfer (Added in 7.12.1)
      # From 7.18.0, the function can return CURL_READFUNC_PAUSE which then
      # will cause reading from this connection to become paused. See
      # curl_easy_pause(3) for further details.
      # Bugs: when doing TFTP uploads, you must return the exact amount of
      # data that the callback wants, or it will be considered the final
      # packet by the server end and the transfer will end there.
      # If you set this callback pointer to NULL, or don't set it at all, the
      # default internal read function will be used. It is doing an fread()
      # on the FILE * userdata set with CURLOPT_READDATA.
      #
      # @example Set readfunction option.
      #   easy.readfunction = value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def readfunction=(value)
        Curl.set_option(:readfunction, value_for(value, :string), handle)
      end

      # Pass a long as parameter.
      # This option determines whether libcurl verifies that the server cert
      # is for the server it is known as.
      # When negotiating a SSL connection, the server sends a certificate
      # indicating its identity.
      # When CURLOPT_SSL_VERIFYHOST is 2, that certificate must indicate that
      # the server is the server to which you meant to connect, or the
      # connection fails.
      # Curl considers the server the intended one when the Common Name field
      # or a Subject Alternate Name field in the certificate matches the host
      # name in the URL to which you told Curl to connect.
      # When the value is 1, the certificate must contain a Common Name
      # field, but it doesn't matter what name it says. (This is not
      # ordinarily a useful setting).
      # When the value is 0, the connection succeeds regardless of the names
      # in the certificate.
      # The default value for this option is 2.
      # This option controls checking the server's certificate's claimed
      # identity. The server could be lying. To control lying, see
      # CURLOPT_SSL_VERIFYPEER. If libcurl is built against NSS and
      # CURLOPT_SSL_VERIFYPEER is zero, CURLOPT_SSL_VERIFYHOST is ignored.
      #
      # @example Set ssl_verifyhost option.
      #   easy.ssl_verifyhost = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def ssl_verifyhost=(value)
        Curl.set_option(:ssl_verifyhost, value_for(value, :int), handle)
      end

      # Pass a long as parameter. By default, curl assumes a value of 1.
      # This option determines whether curl verifies the authenticity of the
      # peer's certificate. A value of 1 means curl verifies; 0 (zero) means
      # it doesn't.
      # When negotiating a SSL connection, the server sends a certificate
      # indicating its identity. Curl verifies whether the certificate is
      # authentic, i.e. that you can trust that the server is who the
      # certificate says it is. This trust is based on a chain of digital
      # signatures, rooted in certification authority (CA) certificates you
      # supply. curl uses a default bundle of CA certificates (the path for
      # that is determined at build time) and you can specify alternate
      # certificates with the CURLOPT_CAINFO option or the CURLOPT_CAPATH
      # option.
      # When CURLOPT_SSL_VERIFYPEER is nonzero, and the verification fails to
      # prove that the certificate is authentic, the connection fails. When
      # the option is zero, the peer certificate verification succeeds
      # regardless.
      # Authenticating the certificate is not by itself very useful. You
      # typically want to ensure that the server, as authentically identified
      # by its certificate, is the server you mean to be talking to. Use
      # CURLOPT_SSL_VERIFYHOST to control that. The check that the host name
      # in the certificate is valid for the host name you're connecting to is
      # done independently of the CURLOPT_SSL_VERIFYPEER option.
      #
      # @example Set ssl_verifypeer option.
      #   easy.ssl_verifypeer = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def ssl_verifypeer=(value)
        Curl.set_option(:ssl_verifypeer, value_for(value, :bool), handle)
      end

      # Pass a pointer to a zero terminated string as parameter. The string
      # should be the file name of your certificate. The default format is
      # "PEM" and can be changed with CURLOPT_SSLCERTTYPE.
      # With NSS this can also be the nickname of the certificate you wish to
      # authenticate with. If you want to use a file from the current
      # directory, please precede it with "./" prefix, in order to avoid
      # confusion with a nickname.
      #
      # @example Set sslcert option.
      #   easy.sslcert = "name"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslcert=(value)
        Curl.set_option(:sslcert, value_for(value, :string), handle)
      end

      # Pass a pointer to a zero terminated string as parameter. The string
      # should be the format of your certificate. Supported formats are "PEM"
      # and "DER". (Added in 7.9.3)
      #
      # @example Set sslcerttype option.
      #   easy.sslcerttype = "PEM"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslcerttype=(value)
        Curl.set_option(:sslcerttype, value_for(value, :string), handle)
      end

      # Pass a pointer to a zero terminated string as parameter. The string
      # should be the file name of your private key. The default format is
      # "PEM" and can be changed with CURLOPT_SSLKEYTYPE.
      #
      # @example Set sslkey option.
      #   easy.sslkey = "/path/to/file"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslkey=(value)
        Curl.set_option(:sslkey, value_for(value, :string), handle)
      end

      # Pass a pointer to a zero terminated string as parameter. The string
      # should be the format of your private key. Supported formats are
      # "PEM", "DER" and "ENG".
      # The format "ENG" enables you to load the private key from a crypto
      # engine. In this case CURLOPT_SSLKEY is used as an identifier passed
      # to the engine. You have to set the crypto engine with
      # CURLOPT_SSLENGINE. "DER" format key file currently does not work
      # because of a bug in OpenSSL.
      #
      # @example Set sslkeytype option.
      #   easy.sslkeytype = "PEM"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslkeytype=(value)
        Curl.set_option(:sslkeytype, value_for(value, :string), handle)
      end

      # Pass a long as parameter to control what version of SSL/TLS to
      # attempt to use. The available options are:
      # Sets sslversion option.
      #
      # @example Set sslversion option.
      #   easy.sslversion = :sslv3
      #
      # @param [ $type_doc ] value The value to set.
      #
      # @return [ void ]
      def sslversion=(value)
        Curl.set_option(:sslversion, value_for(value, :enum, :sslversion), handle)
      end

      # Pass a long as parameter containing the maximum time in seconds that
      # you allow the libcurl transfer operation to take. Normally, name
      # lookups can take a considerable time and limiting operations to less
      # than a few minutes risk aborting perfectly normal operations. This
      # option will cause curl to use the SIGALRM to enable time-outing
      # system calls.
      # In unix-like systems, this might cause signals to be used unless
      # CURLOPT_NOSIGNAL is set.
      # Default timeout is 0 (zero) which means it never times out.
      #
      # @example Set timeout option.
      #   easy.timeout = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def timeout=(value)
        Curl.set_option(:timeout, value_for(value, :int), handle)
      end

      # Like CURLOPT_TIMEOUT but takes number of milliseconds instead. If
      # libcurl is built to use the standard system name resolver, that
      # portion of the transfer will still use full-second resolution for
      # timeouts with a minimum timeout allowed of one second. (Added in
      # 7.16.2)
      #
      # @example Set timeout_ms option.
      #   easy.timeout_ms = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def timeout_ms=(value)
        Curl.set_option(:timeout_ms, value_for(value, :int), handle)
      end

      # A parameter set to 1 tells the library it can continue to send
      # authentication (user+password) when following locations, even
      # when hostname changed. This option is meaningful only when setting
      # CURLOPT_FOLLOWLOCATION.
      #
      # @example Set unrestricted auth.
      #   easy.unrestricted_auth = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def unrestricted_auth=(value)
        Curl.set_option(:unrestricted_auth, value_for(value, :bool), handle)
      end

      # A parameter set to 1 tells the library to prepare for an upload. The
      # CURLOPT_READDATA and CURLOPT_INFILESIZE or CURLOPT_INFILESIZE_LARGE
      # options are also interesting for uploads. If the protocol is HTTP,
      # uploading means using the PUT request unless you tell libcurl
      # otherwise.
      # Using PUT with HTTP 1.1 implies the use of a "Expect: 100-continue"
      # header. You can disable this header with CURLOPT_HTTPHEADER as usual.
      # If you use PUT to a HTTP 1.1 server, you can upload data without
      # knowing the size before starting the transfer if you use chunked
      # encoding. You enable this by adding a header like "Transfer-Encoding:
      # chunked" with CURLOPT_HTTPHEADER. With HTTP 1.0 or without chunked
      # transfer, you must specify the size.
      #
      # @example Set upload option.
      #   easy.upload = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def upload=(value)
        Curl.set_option(:upload, value_for(value, :bool), handle)
      end

      # Pass in a pointer to the actual URL to deal with. The parameter
      # should be a string to a zero terminated string which must be
      # URL-encoded in the following format:
      # scheme://host:port/path
      # For a greater explanation of the format please see RFC 3986.
      # If the given URL lacks the scheme, or protocol, part ("http://" or
      # "ftp://" etc), libcurl will attempt to resolve which protocol to use
      # based on the given host mame. If the protocol is not supported,
      # libcurl will return (CURLE_UNSUPPORTED_PROTOCOL) when you call
      # curl_easy_perform(3) or curl_multi_perform(3). Use
      # curl_version_info(3) for detailed information on which protocols are
      # supported.
      # The host part of the URL contains the address of the server that you
      # want to connect to. This can be the fully qualified domain name of
      # the server, the local network name of the machine on your network or
      # the IP address of the server or machine represented by either an IPv4
      # or IPv6 address. For example:
      # http://www.example.com/
      # http://hostname/
      # http://192.168.0.1/
      # http://[2001:1890:1112:1::20]/
      # It is also possible to specify the user name and password as part of
      # the host, for some protocols, when connecting to servers that require
      # authentication.
      # For example the following types of authentication support this:
      # http://user:password@www.example.com
      # ftp://user:password@ftp.example.com
      # pop3://user:password@mail.example.com
      # The port is optional and when not specified libcurl will use the
      # default port based on the determined or specified protocol: 80 for
      # HTTP, 21 for FTP and 25 for SMTP, etc. The following examples show
      # how to specify the port:
      # http://www.example.com:8080/ - This will connect to a web server
      # using port 8080 rather than 80.
      # smtp://mail.example.com:587/ - This will connect to a SMTP server on
      # the alternative mail port.
      # The path part of the URL is protocol specific and whilst some
      # examples are given below this list is not conclusive:
      # HTTP
      # The path part of a HTTP request specifies the file to retrieve and
      # from what directory. If the directory is not specified then the web
      # server's root directory is used. If the file is omitted then the
      # default document will be retrieved for either the directory specified
      # or the root directory. The exact resource returned for each URL is
      # entirely dependent on the server's configuration.
      # http://www.example.com - This gets the main page from the web server.
      # http://www.example.com/index.html - This returns the main page by
      # explicitly requesting it.
      # http://www.example.com/contactus/ - This returns the default document
      # from the contactus directory.
      # FTP
      # The path part of an FTP request specifies the file to retrieve and
      # from what directory. If the file part is omitted then libcurl
      # downloads the directory listing for the directory specified. If the
      # directory is omitted then the directory listing for the root / home
      # directory will be returned.
      # ftp://ftp.example.com - This retrieves the directory listing for the
      # root directory.
      # ftp://ftp.example.com/readme.txt - This downloads the file readme.txt
      # from the root directory.
      # ftp://ftp.example.com/libcurl/readme.txt - This downloads readme.txt
      # from the libcurl directory.
      # ftp://user:password@ftp.example.com/readme.txt - This retrieves the
      # readme.txt file from the user's home directory. When a username and
      # password is specified, everything that is specified in the path part
      # is relative to the user's home directory. To retrieve files from the
      # root directory or a directory underneath the root directory then the
      # absolute path must be specified by prepending an additional forward
      # slash to the beginning of the path.
      # ftp://user:password@ftp.example.com//readme.txt - This retrieves the
      # readme.txt from the root directory when logging in as a specified
      # user.
      # SMTP
      # The path part of a SMTP request specifies the host name to present
      # during communication with the mail server. If the path is omitted
      # then libcurl will attempt to resolve the local computer's host name.
      # However, this may not return the fully qualified domain name that is
      # required by some mail servers and specifying this path allows you to
      # set an alternative name, such as your machine's fully qualified
      # domain name, which you might have obtained from an external function
      # such as gethostname or getaddrinfo.
      # smtp://mail.example.com - This connects to the mail server at
      # example.com and sends your local computer's host name in the HELO /
      # EHLO command.
      # smtp://mail.example.com/client.example.com - This will send
      # client.example.com in the HELO / EHLO command to the mail server at
      # example.com.
      # POP3
      # The path part of a POP3 request specifies the mailbox (message) to
      # retrieve. If the mailbox is not specified then a list of waiting
      # messages is returned instead.
      # pop3://user:password@mail.example.com - This lists the available
      # messages pop3://user:password@mail.example.com/1 - This retrieves the
      # first message
      # SCP
      # The path part of a SCP request specifies the file to retrieve and
      # from what directory. The file part may not be omitted. The file is
      # taken as an absolute path from the root directory on the server. To
      # specify a path relative to the user's home directory on the server,
      # prepend ~/ to the path portion. If the user name is not embedded in
      # the URL, it can be set with the CURLOPT_USERPWD or CURLOPT_USERNAME
      # option.
      # scp://user@example.com/etc/issue - This specifies the file /etc/issue
      # scp://example.com/~/my-file - This specifies the file my-file in the
      # user's home directory on the server
      # SFTP
      # The path part of a SFTP request specifies the file to retrieve and
      # from what directory. If the file part is omitted then libcurl
      # downloads the directory listing for the directory specified. If the
      # path ends in a / then a directory listing is returned instead of a
      # file. If the path is omitted entirely then the directory listing for
      # the root / home directory will be returned. If the user name is not
      # embedded in the URL, it can be set with the CURLOPT_USERPWD or
      # CURLOPT_USERNAME option.
      # sftp://user:password@example.com/etc/issue - This specifies the file
      # /etc/issue
      # sftp://user@example.com/~/my-file - This specifies the file my-file
      # in the user's home directory
      # sftp://ssh.example.com/~/Documents/ - This requests a directory
      # listing of the Documents directory under the user's home directory
      # LDAP
      # The path part of a LDAP request can be used to specify the:
      # Distinguished Name, Attributes, Scope, Filter and Extension for a
      # LDAP search. Each field is separated by a question mark and when that
      # field is not required an empty string with the question mark
      # separator should be included.
      # ldap://ldap.example.com/o=My%20Organisation - This will perform a
      # LDAP search with the DN as My Organisation.
      # ldap://ldap.example.com/o=My%20Organisation?postalAddress - This will
      # perform the same search but will only return postalAddress attributes.
      # ldap://ldap.example.com/?rootDomainNamingContext - This specifies an
      # empty DN and requests information about the rootDomainNamingContext
      # attribute for an Active Directory server.
      # For more information about the individual components of a LDAP URL
      # please see RFC 4516.
      # NOTES
      # Starting with version 7.20.0, the fragment part of the URI will not
      # be sent as part of the path, which was previously the case.
      # CURLOPT_URL is the only option that must be set before
      # curl_easy_perform(3) is called.
      # CURLOPT_PROTOCOLS can be used to limit what protocols libcurl will
      # use for this transfer, independent of what libcurl has been compiled
      # to support. That may be useful if you accept the URL from an external
      # source and want to limit the accessibility.
      #
      # @example Set url option.
      #   easy.url = "www.example.com"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def url=(value)
        @url = value
        Curl.set_option(:url, value_for(value, :string), handle)
      end

      # Pass a pointer to a zero terminated string as parameter. It will be
      # used to set the User-Agent: header in the http request sent to the
      # remote server. This can be used to fool servers or scripts. You can
      # also set any custom header with CURLOPT_HTTPHEADER.
      #
      # @example Set useragent option.
      #   easy.useragent = "UserAgent"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def useragent=(value)
        Curl.set_option(:useragent, value_for(value, :string), handle)
      end

      # Pass a string as parameter, which should be [user name]:[password] to
      # use for the connection. Use CURLOPT_HTTPAUTH to decide the
      # authentication method.
      # When using NTLM, you can set the domain by prepending it to the user
      # name and separating the domain and name with a forward (/) or
      # backward slash (\). Like this: "domain/user:password" or
      # "domain\user:password". Some HTTP servers (on Windows) support this
      # style even for Basic authentication.
      # When using HTTP and CURLOPT_FOLLOWLOCATION, libcurl might perform
      # several requests to possibly different hosts. libcurl will only send
      # this user and password information to hosts using the initial host
      # name (unless CURLOPT_UNRESTRICTED_AUTH is set), so if libcurl follows
      # locations to other hosts it will not send the user and password to
      # those. This is enforced to prevent accidental information leakage.
      #
      # @example Set userpwd option.
      #   easy.userpwd = "user:password"
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def userpwd=(value)
        Curl.set_option(:userpwd, value_for(value, :string), handle)
      end

      # Set the parameter to 1 to get the library to display a lot of verbose
      # information about its operations. Very useful for libcurl and/or
      # protocol debugging and understanding. The verbose information will be
      # sent to stderr, or the stream set with CURLOPT_STDERR.
      # You hardly ever want this set in production use, you will almost
      # always want this when you debug/report problems. Another neat option
      # for debugging is the CURLOPT_DEBUGFUNCTION.
      # Sets verbose option.
      #
      # @example Set verbose option.
      #   easy.verbose = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def verbose=(value)
        Curl.set_option(:verbose, value_for(value, :bool), handle)
      end

      private

      # Return the value to set to easy handle. It is converted with the help
      # of bool_options, enum_options and int_options.
      #
      # @example Return casted the value.
      #   easy.value_for(:verbose)
      #
      # @param [ Symbol ] option The option to get the value from.
      #
      # @return [ Object ] The casted value.
      #
      # @raise [ Ethon::Errors::InvalidValue ] If specified option
      #   points to an enum and the value doen't correspond to
      #   the valid values.
      def value_for(value, type, option = nil)
        return nil if value.nil?

        if type == :bool
          value ? 1 : 0
        elsif type == :int
          value.to_i
        elsif type == :enum && option == :httpauth
          Curl::Auth.to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
        elsif type == :enum && option == :sslversion
          Curl::SSLVersion.to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
        elsif type == :enum && option == :http_version
          Curl::HTTPVersion.to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
        elsif type == :enum && (option == :protocols || option == :redir_protocols)
          Array(value).map do |v|
            Curl::Protocols.to_h.fetch(v) do
              raise Errors::InvalidValue.new(option, v)
            end
          end.inject(:+)
        elsif type == :enum && option == :postredir
          Array(value).map do |v|
            Curl::Postredir.to_h.fetch(v) do
              raise Errors::InvalidValue.new(option, v)
            end
          end.inject(:+)
        elsif type == :enum && option == :proxytype
          Curl::Proxy.to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
        elsif value.is_a?(String)
          Util.escape_zero_byte(value)
        else
          value
        end
      end
    end
  end
end
