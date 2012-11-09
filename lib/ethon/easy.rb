require 'ethon/easy/informations'
require 'ethon/easy/callbacks'
require 'ethon/easy/options'
require 'ethon/easy/header'
require 'ethon/easy/util'
require 'ethon/easy/params'
require 'ethon/easy/form'
require 'ethon/easy/http'
require 'ethon/easy/operations'
require 'ethon/easy/response_callbacks'

module Ethon

  # This is the class representing the libcurl easy interface
  # See http://curl.haxx.se/libcurl/c/libcurl-easy.html for more informations.
  #
  # @example You can access the libcurl easy interface through this class, every request is based on it. The simplest setup looks like that:
  #
  #   e = Ethon::Easy.new(url: "www.example.com")
  #   e.perform
  #   #=> :ok
  #
  # @example You can the reuse this Easy for the next request:
  #
  #   e.reset # reset easy handle
  #   e.url = "www.google.com"
  #   e.followlocation = true
  #   e.perform
  #   #=> :ok
  #
  # @see initialize
  class Easy
    include Ethon::Easy::Informations
    include Ethon::Easy::Callbacks
    include Ethon::Easy::Options
    include Ethon::Easy::Header
    include Ethon::Easy::Http
    include Ethon::Easy::Operations
    include Ethon::Easy::ResponseCallbacks

    # Returns the curl return code.
    #
    # @return [ Symbol ] The return code.
    #   * :ok: All fine. Proceed as usual.
    #   * :unsupported_protocol: The URL you passed to libcurl used a
    #     protocol that this libcurl does not support. The support
    #     might be a compile-time option that you didn't use, it can
    #     be a misspelled protocol string or just a protocol
    #     libcurl has no code for.
    #   * :failed_init: Very early initialization code failed. This
    #     is likely to be an internal error or problem, or a
    #     resource problem where something fundamental couldn't
    #     get done at init time.
    #   * :url_malformat: The URL was not properly formatted.
    #   * :not_built_in: A requested feature, protocol or option
    #     was not found built-in in this libcurl due to a build-time
    #     decision. This means that a feature or option was not enabled
    #     or explicitly disabled when libcurl was built and in
    #     order to get it to function you have to get a rebuilt libcurl.
    #   * :couldnt_resolve_proxy: Couldn't resolve proxy. The given
    #     proxy host could not be resolved.
    #   * :couldnt_resolve_host: Couldn't resolve host. The given remote
    #     host was not resolved.
    #   * :couldnt_connect: Failed to connect() to host or proxy.
    #   * :ftp_weird_server_reply: After connecting to a FTP server,
    #     libcurl expects to get a certain reply back. This error
    #     code implies that it got a strange or bad reply. The given
    #     remote server is probably not an OK FTP server.
    #   * :remote_access_denied: We were denied access to the resource
    #     given in the URL. For FTP, this occurs while trying to
    #     change to the remote directory.
    #   * :ftp_accept_failed: While waiting for the server to connect
    #     back when an active FTP session is used, an error code was
    #     sent over the control connection or similar.
    #   * :ftp_weird_pass_reply: After having sent the FTP password to
    #     the server, libcurl expects a proper reply. This error code
    #     indicates that an unexpected code was returned.
    #   * :ftp_accept_timeout: During an active FTP session while
    #     waiting for the server to connect, the CURLOPT_ACCEPTTIMOUT_MS
    #     (or the internal default) timeout expired.
    #   * :ftp_weird_pasv_reply: libcurl failed to get a sensible result
    #     back from the server as a response to either a PASV or a
    #     EPSV command. The server is flawed.
    #   * :ftp_weird_227_format: FTP servers return a 227-line as a response
    #     to a PASV command. If libcurl fails to parse that line,
    #     this return code is passed back.
    #   * :ftp_cant_get_host: An internal failure to lookup the host used
    #     for the new connection.
    #   * :ftp_couldnt_set_type: Received an error when trying to set
    #     the transfer mode to binary or ASCII.
    #   * :partial_file: A file transfer was shorter or larger than
    #     expected. This happens when the server first reports an expected
    #     transfer size, and then delivers data that doesn't match the
    #     previously given size.
    #   * :ftp_couldnt_retr_file: This was either a weird reply to a
    #     'RETR' command or a zero byte transfer complete.
    #   * :quote_error: When sending custom "QUOTE" commands to the
    #     remote server, one of the commands returned an error code that
    #     was 400 or higher (for FTP) or otherwise indicated unsuccessful
    #     completion of the command.
    #   * :http_returned_error: This is returned if CURLOPT_FAILONERROR is
    #     set TRUE and the HTTP server returns an error code that is >= 400.
    #   * :write_error: An error occurred when writing received data to a
    #     local file, or an error was returned to libcurl from a write callback.
    #   * :upload_failed: Failed starting the upload. For FTP, the server
    #     typically denied the STOR command. The error buffer usually
    #     contains the server's explanation for this.
    #   * :read_error: There was a problem reading a local file or an error
    #     returned by the read callback.
    #   * :out_of_memory: A memory allocation request failed. This is serious
    #     badness and things are severely screwed up if this ever occurs.
    #   * :operation_timedout: Operation timeout. The specified time-out
    #     period was reached according to the conditions.
    #   * :ftp_port_failed: The FTP PORT command returned error. This mostly
    #     happens when you haven't specified a good enough address for
    #     libcurl to use. See CURLOPT_FTPPORT.
    #   * :ftp_couldnt_use_rest: The FTP REST command returned error. This
    #     should never happen if the server is sane.
    #   * :range_error: The server does not support or accept range requests.
    #   * :http_post_error: This is an odd error that mainly occurs due to
    #     internal confusion.
    #   * :ssl_connect_error: A problem occurred somewhere in the SSL/TLS
    #     handshake. You really want the error buffer and read the message
    #     there as it pinpoints the problem slightly more. Could be
    #     certificates (file formats, paths, permissions), passwords, and others.
    #   * :bad_download_resume: The download could not be resumed because
    #     the specified offset was out of the file boundary.
    #   * :file_couldnt_read_file: A file given with FILE:// couldn't be
    #     opened. Most likely because the file path doesn't identify an
    #     existing file. Did you check file permissions?
    #   * :ldap_cannot_bind: LDAP cannot bind. LDAP bind operation failed.
    #   * :ldap_search_failed: LDAP search failed.
    #   * :function_not_found: Function not found. A required zlib function was not found.
    #   * :aborted_by_callback: Aborted by callback. A callback returned
    #     "abort" to libcurl.
    #   * :bad_function_argument: Internal error. A function was called with
    #     a bad parameter.
    #   * :interface_failed: Interface error. A specified outgoing interface
    #     could not be used. Set which interface to use for outgoing
    #     connections' source IP address with CURLOPT_INTERFACE.
    #   * :too_many_redirects: Too many redirects. When following redirects,
    #     libcurl hit the maximum amount. Set your limit with CURLOPT_MAXREDIRS.
    #   * :unknown_option: An option passed to libcurl is not recognized/known.
    #     Refer to the appropriate documentation. This is most likely a
    #     problem in the program that uses libcurl. The error buffer might
    #     contain more specific information about which exact option it concerns.
    #   * :telnet_option_syntax: A telnet option string was Illegally formatted.
    #   * :peer_failed_verification: The remote server's SSL certificate or
    #     SSH md5 fingerprint was deemed not OK.
    #   * :got_nothing: Nothing was returned from the server, and under the
    #     circumstances, getting nothing is considered an error.
    #   * :ssl_engine_notfound: The specified crypto engine wasn't found.
    #   * :ssl_engine_setfailed: Failed setting the selected SSL crypto engine as default!
    #   * :send_error: Failed sending network data.
    #   * :recv_error: Failure with receiving network data.
    #   * :ssl_certproblem: problem with the local client certificate.
    #   * :ssl_cipher: Couldn't use specified cipher.
    #   * :ssl_cacert: Peer certificate cannot be authenticated with known CA certificates.
    #   * :bad_content_encoding: Unrecognized transfer encoding.
    #   * :ldap_invalid_url: Invalid LDAP URL.
    #   * :filesize_exceeded: Maximum file size exceeded.
    #   * :use_ssl_failed: Requested FTP SSL level failed.
    #   * :send_fail_rewind: When doing a send operation curl had to rewind the data to
    #     retransmit, but the rewinding operation failed.
    #   * :ssl_engine_initfailed: Initiating the SSL Engine failed.
    #   * :login_denied: The remote server denied curl to login
    #   * :tftp_notfound: File not found on TFTP server.
    #   * :tftp_perm: Permission problem on TFTP server.
    #   * :remote_disk_full: Out of disk space on the server.
    #   * :tftp_illegal: Illegal TFTP operation.
    #   * :tftp_unknownid: Unknown TFTP transfer ID.
    #   * :remote_file_exists: File already exists and will not be overwritten.
    #   * :tftp_nosuchuser: This error should never be returned by a properly
    #     functioning TFTP server.
    #   * :conv_failed: Character conversion failed.
    #   * :conv_reqd: Caller must register conversion callbacks.
    #   * :ssl_cacert_badfile: Problem with reading the SSL CA cert (path? access rights?):
    #   * :remote_file_not_found: The resource referenced in the URL does not exist.
    #   * :ssh: An unspecified error occurred during the SSH session.
    #   * :ssl_shutdown_failed: Failed to shut down the SSL connection.
    #   * :again: Socket is not ready for send/recv wait till it's ready and try again.
    #     This return code is only returned from curl_easy_recv(3) and curl_easy_send(3)
    #   * :ssl_crl_badfile: Failed to load CRL file
    #   * :ssl_issuer_error: Issuer check failed
    #   * :ftp_pret_failed: The FTP server does not understand the PRET command at
    #     all or does not support the given argument. Be careful when
    #     using CURLOPT_CUSTOMREQUEST, a custom LIST command will be sent with PRET CMD
    #     before PASV as well.
    #   * :rtsp_cseq_error: Mismatch of RTSP CSeq numbers.
    #   * :rtsp_session_error: Mismatch of RTSP Session Identifiers.
    #   * :ftp_bad_file_list: Unable to parse FTP file list (during FTP wildcard downloading).
    #   * :chunk_failed: Chunk callback reported error.
    #   * :obsolete: These error codes will never be returned. They were used in an old
    #     libcurl version and are currently unused.
    #
    #
    # @see http://curl.haxx.se/libcurl/c/libcurl-errors.html
    attr_accessor :return_code

    class << self

      # Frees libcurls easy represantation including its headers if any.
      #
      # @example Free easy handle.
      #   Easy.finalizer(easy)
      #
      # @param [ Easy ] easy The easy to free.
      #
      # @see http://curl.haxx.se/libcurl/c/curl_easy_cleanup.html
      #
      # @api private
      def finalizer(easy)
        proc {
          Curl.slist_free_all(easy.header_list) if easy.header_list
          Curl.easy_cleanup(easy.handle)
        }
      end
    end

    # Initialize a new Easy.
    # It initializes curl, if not already done and applies the provided options.
    #
    # @example Create a new Easy.
    #   Easy.new(url: "www.google.de")
    #
    # @param [ Hash ] options The options to set.
    #
    # @option options :cainfo [String] Pass a char * to a zero terminated
    #  string naming a file holding one or more certificates to verify
    #  the peer with. This makes sense only when used in combination with
    #  the CURLOPT_SSL_VERIFYPEER option. If CURLOPT_SSL_VERIFYPEER is
    #  zero, CURLOPT_CAINFO need not even indicate an accessible file.
    #  This option is by default set to the system path where libcurl's
    #  cacert bundle is assumed to be stored, as established at build time.
    #  When built against NSS, this is the directory that the NSS certificate
    #  database resides in.
    # @option options :capath [String]
    #  Pass a char * to a zero terminated string naming a directory holding
    #  multiple CA certificates to verify the peer with. If libcurl is built
    #  against OpenSSL, the certificate directory must be prepared using the
    #  openssl c_rehash utility. This makes sense only when used in
    #  combination with the CURLOPT_SSL_VERIFYPEER option. If
    #  CURLOPT_SSL_VERIFYPEER is zero, CURLOPT_CAPATH need not even indicate
    #  an accessible path. The CURLOPT_CAPATH function apparently does not
    #  work in Windows due to some limitation in openssl. This option is
    #  OpenSSL-specific and does nothing if libcurl is built to use GnuTLS.
    #  NSS-powered libcurl provides the option only for backward
    #  compatibility.
    # @option options :connecttimeout [Integer]
    #  Pass a long. It should contain the maximum time in seconds that you
    #  allow the connection to the server to take. This only limits the
    #  connection phase, once it has connected, this option is of no more
    #  use. Set to zero to switch to the default built-in connection timeout
    #  \- 300 seconds. See also the CURLOPT_TIMEOUT option.
    #  In unix-like systems, this might cause signals to be used unless
    #  CURLOPT_NOSIGNAL is set.
    # @option options :connecttimeout_ms [Integer]
    #  Like CURLOPT_CONNECTTIMEOUT but takes the number of milliseconds
    #  instead. If libcurl is built to use the standard system name
    #  resolver, that portion of the connect will still use full-second
    #  resolution for timeouts with a minimum timeout allowed of one second.
    #  (Added in 7.16.2)
    # @option options :copypostfields [String]
    #  Pass a char * as parameter, which should be the full data to post in
    #  a HTTP POST operation. It behaves as the CURLOPT_POSTFIELDS option,
    #  but the original data are copied by the library, allowing the
    #  application to overwrite the original data after setting this option.
    #  Because data are copied, care must be taken when using this option in
    #  conjunction with CURLOPT_POSTFIELDSIZE or
    #  CURLOPT_POSTFIELDSIZE_LARGE: If the size has not been set prior to
    #  CURLOPT_COPYPOSTFIELDS, the data are assumed to be a NUL-terminated
    #  string; else the stored size informs the library about the data byte
    #  count to copy. In any case, the size must not be changed after
    #  CURLOPT_COPYPOSTFIELDS, unless another CURLOPT_POSTFIELDS or
    #  CURLOPT_COPYPOSTFIELDS option is issued. (Added in 7.17.1)
    # @option options :customrequest [String]
    #  Pass a pointer to a zero terminated string as parameter. It can be
    #  used to specify the request instead of GET or HEAD when performing
    #  HTTP based requests, instead of LIST and NLST when performing FTP
    #  directory listings and instead of LIST and RETR when issuing POP3
    #  based commands. This is particularly useful, for example, for
    #  performing a HTTP DELETE request or a POP3 DELE command.
    #  Please don't perform this at will, on HTTP based requests, by making
    #  sure your server supports the command you are sending first.
    #  When you change the request method by setting CURLOPT_CUSTOMREQUEST
    #  to something, you don't actually change how libcurl behaves or acts
    #  in regards to the particular request method, it will only change the
    #  actual string sent in the request.
    #  For example:
    #  With the HTTP protocol when you tell libcurl to do a HEAD request,
    #  but then specify a GET though a custom request libcurl will still act
    #  as if it sent a HEAD. To switch to a proper HEAD use CURLOPT_NOBODY,
    #  to switch to a proper POST use CURLOPT_POST or CURLOPT_POSTFIELDS and
    #  to switch to a proper GET use CURLOPT_HTTPGET.
    #  With the POP3 protocol when you tell libcurl to use a custom request
    #  it will behave like a LIST or RETR command was sent where it expects
    #  data to be returned by the server. As such CURLOPT_NOBODY should be
    #  used when specifying commands such as DELE and NOOP for example.
    #  Restore to the internal default by setting this to NULL.
    #  Many people have wrongly used this option to replace the entire
    #  request with their own, including multiple headers and POST contents.
    #  While that might work in many cases, it will cause libcurl to send
    #  invalid requests and it could possibly confuse the remote server
    #  badly. Use CURLOPT_POST and CURLOPT_POSTFIELDS to set POST data. Use
    #  CURLOPT_HTTPHEADER to replace or extend the set of headers sent by
    #  libcurl. Use CURLOPT_HTTP_VERSION to change HTTP version.
    #  (Support for POP3 added in 7.26.0)
    # @option options :dns_cache_timeout [Integer]
    #  Pass a long, this sets the timeout in seconds. Name resolves will be
    #  kept in memory for this number of seconds. Set to zero to completely
    #  disable caching, or set to -1 to make the cached entries remain
    #  forever. By default, libcurl caches this info for 60 seconds.
    #  The name resolve functions of various libc implementations don't
    #  re-read name server information unless explicitly told so (for
    #  example, by calling res_init(3)). This may cause libcurl to keep
    #  using the older server even if DHCP has updated the server info, and
    #  this may look like a DNS cache issue to the casual libcurl-app user.
    # @option options :followlocation [Boolean]
    #  A parameter set to 1 tells the library to follow any Location: header
    #  that the server sends as part of a HTTP header.
    #  This means that the library will re-send the same request on the new
    #  location and follow new Location: headers all the way until no more
    #  such headers are returned. CURLOPT_MAXREDIRS can be used to limit the
    #  number of redirects libcurl will follow.
    #  Since 7.19.4, libcurl can limit what protocols it will automatically
    #  follow. The accepted protocols are set with CURLOPT_REDIR_PROTOCOLS
    #  and it excludes the FILE protocol by default.
    # @option options :forbid_reuse [Boolean]
    #  Pass a long. Set to 1 to make the next transfer explicitly close the
    #  connection when done. Normally, libcurl keeps all connections alive
    #  when done with one transfer in case a succeeding one follows that can
    #  re-use them. This option should be used with caution and only if you
    #  understand what it does. Set to 0 to have libcurl keep the connection
    #  open for possible later re-use (default behavior).
    # @option options :httpauth [String]
    #  Pass a long as parameter, which is set to a bitmask, to tell libcurl
    #  which authentication method(s) you want it to use. The available bits
    #  are listed below. If more than one bit is set, libcurl will first
    #  query the site to see which authentication methods it supports and
    #  then pick the best one you allow it to use. For some methods, this
    #  will induce an extra network round-trip. Set the actual name and
    #  password with the CURLOPT_USERPWD option or with the CURLOPT_USERNAME
    #  and the CURLOPT_PASSWORD options. (Added in 7.10.6)
    # @option options :httpget [Boolean]
    #  Pass a long. If the long is 1, this forces the HTTP request to get
    #  back to GET. Usable if a POST, HEAD, PUT, or a custom request has
    #  been used previously using the same curl handle.
    #  When setting CURLOPT_HTTPGET to 1, it will automatically set
    #  CURLOPT_NOBODY to 0 (since 7.14.1).
    # @option options :httppost [String]
    #  Tells libcurl you want a multipart/formdata HTTP POST to be made and
    #  you instruct what data to pass on to the server. Pass a pointer to a
    #  linked list of curl_httppost structs as parameter. The easiest way to
    #  create such a list, is to use curl_formadd(3) as documented. The data
    #  in this list must remain intact until you close this curl handle
    #  again with curl_easy_cleanup(3).
    #  Using POST with HTTP 1.1 implies the use of a "Expect: 100-continue"
    #  header. You can disable this header with CURLOPT_HTTPHEADER as usual.
    #  When setting CURLOPT_HTTPPOST, it will automatically set
    #  CURLOPT_NOBODY to 0 (since 7.14.1).
    # @option options :infilesize [Integer]
    #  When uploading a file to a remote site, this option should be used to
    #  tell libcurl what the expected size of the infile is. This value
    #  should be passed as a long. See also CURLOPT_INFILESIZE_LARGE.
    #  For uploading using SCP, this option or CURLOPT_INFILESIZE_LARGE is
    #  mandatory.
    #  When sending emails using SMTP, this command can be used to specify
    #  the optional SIZE parameter for the MAIL FROM command. (Added in
    #  7.23.0)
    #  This option does not limit how much data libcurl will actually send,
    #  as that is controlled entirely by what the read callback returns.
    # @option options :interface [String]
    #  Pass a char * as parameter. This sets the interface name to use as
    #  outgoing network interface. The name can be an interface name, an IP
    #  address, or a host name.
    #  Starting with 7.24.0: If the parameter starts with "if!" then it is
    #  treated as only as interface name and no attempt will ever be named
    #  to do treat it as an IP address or to do name resolution on it. If
    #  the parameter starts with "host!" it is treated as either an IP
    #  address or a hostname. Hostnames are resolved synchronously. Using
    #  the if! format is highly recommended when using the multi interfaces
    #  to avoid allowing the code to block. If "if!" is specified but the
    #  parameter does not match an existing interface,
    #  CURLE_INTERFACE_FAILED is returned.
    # @option options :keypasswd [String]
    #  Pass a pointer to a zero terminated string as parameter. It will be
    #  used as the password required to use the CURLOPT_SSLKEY or
    #  CURLOPT_SSH_PRIVATE_KEYFILE private key. You never needed a pass
    #  phrase to load a certificate but you need one to load your private key.
    #  (This option was known as CURLOPT_SSLKEYPASSWD up to 7.16.4 and
    #  CURLOPT_SSLCERTPASSWD up to 7.9.2)
    # @option options :maxredirs [Integer]
    #  Pass a long. The set number will be the redirection limit. If that
    #  many redirections have been followed, the next redirect will cause an
    #  error (CURLE_TOO_MANY_REDIRECTS). This option only makes sense if the
    #  CURLOPT_FOLLOWLOCATION is used at the same time. Added in 7.15.1:
    #  Setting the limit to 0 will make libcurl refuse any redirect. Set it
    #  to -1 for an infinite number of redirects (which is the default)
    # @option options :nobody [Boolean]
    #  A parameter set to 1 tells the library to not include the body-part
    #  in the output. This is only relevant for protocols that have separate
    #  header and body parts. On HTTP(S) servers, this will make libcurl do
    #  a HEAD request.
    #  To change request to GET, you should use CURLOPT_HTTPGET. Change
    #  request to POST with CURLOPT_POST etc.
    # @option options :nosignal [Boolean]
    #  Pass a long. If it is 1, libcurl will not use any functions that
    #  install signal handlers or any functions that cause signals to be
    #  sent to the process. This option is mainly here to allow
    #  multi-threaded unix applications to still set/use all timeout options
    #  etc, without risking getting signals. (Added in 7.10)
    #  If this option is set and libcurl has been built with the standard
    #  name resolver, timeouts will not occur while the name resolve takes
    #  place. Consider building libcurl with c-ares support to enable
    #  asynchronous DNS lookups, which enables nice timeouts for name
    #  resolves without signals.
    #  Setting CURLOPT_NOSIGNAL to 1 makes libcurl NOT ask the system to
    #  ignore SIGPIPE signals, which otherwise are sent by the system when
    #  trying to send data to a socket which is closed in the other end.
    #  libcurl makes an effort to never cause such SIGPIPEs to trigger, but
    #  some operating systems have no way to avoid them and even on those
    #  that have there are some corner cases when they may still happen,
    #  contrary to our desire. In addition, using CURLAUTH_NTLM_WB
    #  authentication could cause a SIGCHLD signal to be raised.
    # @option options :postfieldsize [Integer]
    #  If you want to post data to the server without letting libcurl do a
    #  strlen() to measure the data size, this option must be used. When
    #  this option is used you can post fully binary data, which otherwise
    #  is likely to fail. If this size is set to -1, the library will use
    #  strlen() to get the size.
    # @option options :proxy [String]
    #  Set HTTP proxy to use. The parameter should be a char * to a zero
    #  terminated string holding the host name or dotted IP address. To
    #  specify port number in this string, append :[port] to the end of the
    #  host name. The proxy string may be prefixed with [protocol]:// since
    #  any such prefix will be ignored. The proxy's port number may
    #  optionally be specified with the separate option. If not specified,
    #  libcurl will default to using port 1080 for proxies.
    #  CURLOPT_PROXYPORT.
    #  When you tell the library to use a HTTP proxy, libcurl will
    #  transparently convert operations to HTTP even if you specify an FTP
    #  URL etc. This may have an impact on what other features of the
    #  library you can use, such as CURLOPT_QUOTE and similar FTP specifics
    #  that don't work unless you tunnel through the HTTP proxy. Such
    #  tunneling is activated with CURLOPT_HTTPPROXYTUNNEL.
    #  libcurl respects the environment variables http_proxy, ftp_proxy,
    #  all_proxy etc, if any of those are set. The CURLOPT_PROXY option does
    #  however override any possibly set environment variables.
    #  Setting the proxy string to "" (an empty string) will explicitly
    #  disable the use of a proxy, even if there is an environment variable
    #  set for it.
    #  Since 7.14.1, the proxy host string given in environment variables
    #  can be specified the exact same way as the proxy can be set with
    #  CURLOPT_PROXY, include protocol prefix (http://) and embedded user +
    #  password.
    #  Since 7.21.7, the proxy string may be specified with a protocol://
    #  prefix to specify alternative proxy protocols. Use socks4://,
    #  socks4a://, socks5:// or socks5h:// (the last one to enable socks5
    #  and asking the proxy to do the resolving, also known as
    #  CURLPROXY_SOCKS5_HOSTNAME type) to request the specific SOCKS version
    #  to be used. No protocol specified, http:// and all others will be
    #  treated as HTTP proxies.
    # @option options :proxyauth [String]
    #  Pass a long as parameter, which is set to a bitmask, to tell libcurl
    #  which authentication method(s) you want it to use for your proxy
    #  authentication. If more than one bit is set, libcurl will first query
    #  the site to see what authentication methods it supports and then pick
    #  the best one you allow it to use. For some methods, this will induce
    #  an extra network round-trip. Set the actual name and password with
    #  the CURLOPT_PROXYUSERPWD option. The bitmask can be constructed by
    #  or'ing together the bits listed above for the CURLOPT_HTTPAUTH
    #  option. As of this writing, only Basic, Digest and NTLM work. (Added
    #  in 7.10.7)
    # @option options :proxytype [String]
    #  Pass a long with this option to set type of the proxy. Available
    #  options for this are CURLPROXY_HTTP, CURLPROXY_HTTP_1_0 (added in
    #  7.19.4), CURLPROXY_SOCKS4 (added in 7.10), CURLPROXY_SOCKS5,
    #  CURLPROXY_SOCKS4A (added in 7.18.0) and CURLPROXY_SOCKS5_HOSTNAME
    #  (added in 7.18.0). The HTTP type is default. (Added in 7.10)
    #  If you set CURLOPT_PROXYTYPE to CURLPROXY_HTTP_1_0, it will only
    #  affect how libcurl speaks to a proxy when CONNECT is used. The HTTP
    #  version used for "regular" HTTP requests is instead controlled with
    #  CURLOPT_HTTP_VERSION.
    # @option options :proxyport [Integer]
    #  Pass a long with this option to set the proxy port to connect to
    #  unless it is specified in the proxy string CURLOPT_PROXY.
    # @option options :proxyuserpwd [String]
    #  Pass a char * as parameter, which should be [user name]:[password]
    #  to use for the connection to the HTTP proxy. Use CURLOPT_PROXYAUTH
    #  to decide the authentication method.
    # @option options :readdata [String]
    #  Data pointer to pass to the file read function. If you use the
    #  CURLOPT_READFUNCTION option, this is the pointer you'll get as input.
    #  If you don't specify a read callback but instead rely on the default
    #  internal read function, this data must be a valid readable FILE *.
    #  If you're using libcurl as a win32 DLL, you MUST use a
    #  CURLOPT_READFUNCTION if you set this option.
    #  This option was also known by the older name CURLOPT_INFILE,
    #  the name CURLOPT_READDATA was introduced in 7.9.7.
    # @option options :readfunction [String]
    #  Pass a pointer to a function that matches the following prototype:
    #  size_t function( void *ptr, size_t size, size_t nmemb, void
    #  *userdata); This function gets called by libcurl as soon as it needs
    #  to read data in order to send it to the peer. The data area pointed
    #  at by the pointer ptr may be filled with at most size multiplied with
    #  nmemb number of bytes. Your function must return the actual number of
    #  bytes that you stored in that memory area. Returning 0 will signal
    #  end-of-file to the library and cause it to stop the current transfer.
    #  If you stop the current transfer by returning 0 "pre-maturely" (i.e
    #  before the server expected it, like when you've said you will upload
    #  N bytes and you upload less than N bytes), you may experience that
    #  the server "hangs" waiting for the rest of the data that won't come.
    #  The read callback may return CURL_READFUNC_ABORT to stop the current
    #  operation immediately, resulting in a CURLE_ABORTED_BY_CALLBACK error
    #  code from the transfer (Added in 7.12.1)
    #  From 7.18.0, the function can return CURL_READFUNC_PAUSE which then
    #  will cause reading from this connection to become paused. See
    #  curl_easy_pause(3) for further details.
    #  Bugs: when doing TFTP uploads, you must return the exact amount of
    #  data that the callback wants, or it will be considered the final
    #  packet by the server end and the transfer will end there.
    #  If you set this callback pointer to NULL, or don't set it at all, the
    #  default internal read function will be used. It is doing an fread()
    #  on the FILE * userdata set with CURLOPT_READDATA.
    # @option options :ssl_verifyhost [Integer]
    #  Pass a long as parameter.
    #  This option determines whether libcurl verifies that the server cert
    #  is for the server it is known as.
    #  When negotiating a SSL connection, the server sends a certificate
    #  indicating its identity.
    #  When CURLOPT_SSL_VERIFYHOST is 2, that certificate must indicate that
    #  the server is the server to which you meant to connect, or the
    #  connection fails.
    #  Curl considers the server the intended one when the Common Name field
    #  or a Subject Alternate Name field in the certificate matches the host
    #  name in the URL to which you told Curl to connect.
    #  When the value is 1, the certificate must contain a Common Name
    #  field, but it doesn't matter what name it says. (This is not
    #  ordinarily a useful setting).
    #  When the value is 0, the connection succeeds regardless of the names
    #  in the certificate.
    #  The default value for this option is 2.
    #  This option controls checking the server's certificate's claimed
    #  identity. The server could be lying. To control lying, see
    #  CURLOPT_SSL_VERIFYPEER. If libcurl is built against NSS and
    #  CURLOPT_SSL_VERIFYPEER is zero, CURLOPT_SSL_VERIFYHOST is ignored.
    # @option options :ssl_verifypeer [Boolean]
    #  Pass a long as parameter. By default, curl assumes a value of 1.
    #  This option determines whether curl verifies the authenticity of the
    #  peer's certificate. A value of 1 means curl verifies; 0 (zero) means
    #  it doesn't.
    #  When negotiating a SSL connection, the server sends a certificate
    #  indicating its identity. Curl verifies whether the certificate is
    #  authentic, i.e. that you can trust that the server is who the
    #  certificate says it is. This trust is based on a chain of digital
    #  signatures, rooted in certification authority (CA) certificates you
    #  supply. curl uses a default bundle of CA certificates (the path for
    #  that is determined at build time) and you can specify alternate
    #  certificates with the CURLOPT_CAINFO option or the CURLOPT_CAPATH
    #  option.
    #  When CURLOPT_SSL_VERIFYPEER is nonzero, and the verification fails to
    #  prove that the certificate is authentic, the connection fails. When
    #  the option is zero, the peer certificate verification succeeds
    #  regardless.
    #  Authenticating the certificate is not by itself very useful. You
    #  typically want to ensure that the server, as authentically identified
    #  by its certificate, is the server you mean to be talking to. Use
    #  CURLOPT_SSL_VERIFYHOST to control that. The check that the host name
    #  in the certificate is valid for the host name you're connecting to is
    #  done independently of the CURLOPT_SSL_VERIFYPEER option.
    # @option options :sslcert [String]
    #  Pass a pointer to a zero terminated string as parameter. The string
    #  should be the file name of your certificate. The default format is
    #  "PEM" and can be changed with CURLOPT_SSLCERTTYPE.
    #  With NSS this can also be the nickname of the certificate you wish to
    #  authenticate with. If you want to use a file from the current
    #  directory, please precede it with "./" prefix, in order to avoid
    #  confusion with a nickname.
    # @option options :sslcerttype [String]
    #  Pass a pointer to a zero terminated string as parameter. The string
    #  should be the format of your certificate. Supported formats are "PEM"
    #  and "DER". (Added in 7.9.3)
    # @option options :sslkey [String]
    #  Pass a pointer to a zero terminated string as parameter. The string
    #  should be the file name of your private key. The default format is
    #  "PEM" and can be changed with CURLOPT_SSLKEYTYPE.
    # @option options :sslkeytype [String]
    #  Pass a pointer to a zero terminated string as parameter. The string
    #  should be the format of your private key. Supported formats are
    #  "PEM", "DER" and "ENG".
    #  The format "ENG" enables you to load the private key from a crypto
    #  engine. In this case CURLOPT_SSLKEY is used as an identifier passed
    #  to the engine. You have to set the crypto engine with
    #  CURLOPT_SSLENGINE. "DER" format key file currently does not work
    #  because of a bug in OpenSSL.
    # @option options :sslversion [String]
    #  Pass a long as parameter to control what version of SSL/TLS to
    #  attempt to use. The available options are:
    # @option options :timeout [Integer]
    #  Pass a long as parameter containing the maximum time in seconds that
    #  you allow the libcurl transfer operation to take. Normally, name
    #  lookups can take a considerable time and limiting operations to less
    #  than a few minutes risk aborting perfectly normal operations. This
    #  option will cause curl to use the SIGALRM to enable time-outing
    #  system calls.
    #  In unix-like systems, this might cause signals to be used unless
    #  CURLOPT_NOSIGNAL is set.
    #  Default timeout is 0 (zero) which means it never times out.
    # @option options :timeout_ms [Integer]
    #  Like CURLOPT_TIMEOUT but takes number of milliseconds instead. If
    #  libcurl is built to use the standard system name resolver, that
    #  portion of the transfer will still use full-second resolution for
    #  timeouts with a minimum timeout allowed of one second. (Added in
    #  7.16.2)
    # @option options :upload [Boolean]
    #  A parameter set to 1 tells the library to prepare for an upload. The
    #  CURLOPT_READDATA and CURLOPT_INFILESIZE or CURLOPT_INFILESIZE_LARGE
    #  options are also interesting for uploads. If the protocol is HTTP,
    #  uploading means using the PUT request unless you tell libcurl
    #  otherwise.
    #  Using PUT with HTTP 1.1 implies the use of a "Expect: 100-continue"
    #  header. You can disable this header with CURLOPT_HTTPHEADER as usual.
    #  If you use PUT to a HTTP 1.1 server, you can upload data without
    #  knowing the size before starting the transfer if you use chunked
    #  encoding. You enable this by adding a header like "Transfer-Encoding:
    #  chunked" with CURLOPT_HTTPHEADER. With HTTP 1.0 or without chunked
    #  transfer, you must specify the size.
    # @option options :url [String]
    #  Pass in a pointer to the actual URL to deal with. The parameter
    #  should be a char * to a zero terminated string which must be
    #  URL-encoded in the following format:
    #  scheme://host:port/path
    #  For a greater explanation of the format please see RFC 3986.
    #  If the given URL lacks the scheme, or protocol, part ("http://" or
    #  "ftp://" etc), libcurl will attempt to resolve which protocol to use
    #  based on the given host mame. If the protocol is not supported,
    #  libcurl will return (CURLE_UNSUPPORTED_PROTOCOL) when you call
    #  curl_easy_perform(3) or curl_multi_perform(3). Use
    #  curl_version_info(3) for detailed information on which protocols are
    #  supported.
    #  The host part of the URL contains the address of the server that you
    #  want to connect to. This can be the fully qualified domain name of
    #  the server, the local network name of the machine on your network or
    #  the IP address of the server or machine represented by either an IPv4
    #  or IPv6 address. For example:
    #  http://www.example.com/
    #  http://hostname/
    #  http://192.168.0.1/
    #  http://[2001:1890:1112:1::20]/
    #  It is also possible to specify the user name and password as part of
    #  the host, for some protocols, when connecting to servers that require
    #  authentication.
    #  For example the following types of authentication support this:
    #  http://user:password@www.example.com
    #  ftp://user:password@ftp.example.com
    #  pop3://user:password@mail.example.com
    #  The port is optional and when not specified libcurl will use the
    #  default port based on the determined or specified protocol: 80 for
    #  HTTP, 21 for FTP and 25 for SMTP, etc. The following examples show
    #  how to specify the port:
    #  http://www.example.com:8080/ - This will connect to a web server
    #  using port 8080 rather than 80.
    #  smtp://mail.example.com:587/ - This will connect to a SMTP server on
    #  the alternative mail port.
    #  The path part of the URL is protocol specific and whilst some
    #  examples are given below this list is not conclusive:
    #  HTTP
    #  The path part of a HTTP request specifies the file to retrieve and
    #  from what directory. If the directory is not specified then the web
    #  server's root directory is used. If the file is omitted then the
    #  default document will be retrieved for either the directory specified
    #  or the root directory. The exact resource returned for each URL is
    #  entirely dependent on the server's configuration.
    #  http://www.example.com - This gets the main page from the web server.
    #  http://www.example.com/index.html - This returns the main page by
    #  explicitly requesting it.
    #  http://www.example.com/contactus/ - This returns the default document
    #  from the contactus directory.
    #  FTP
    #  The path part of an FTP request specifies the file to retrieve and
    #  from what directory. If the file part is omitted then libcurl
    #  downloads the directory listing for the directory specified. If the
    #  directory is omitted then the directory listing for the root / home
    #  directory will be returned.
    #  ftp://ftp.example.com - This retrieves the directory listing for the
    #  root directory.
    #  ftp://ftp.example.com/readme.txt - This downloads the file readme.txt
    #  from the root directory.
    #  ftp://ftp.example.com/libcurl/readme.txt - This downloads readme.txt
    #  from the libcurl directory.
    #  ftp://user:password@ftp.example.com/readme.txt - This retrieves the
    #  readme.txt file from the user's home directory. When a username and
    #  password is specified, everything that is specified in the path part
    #  is relative to the user's home directory. To retrieve files from the
    #  root directory or a directory underneath the root directory then the
    #  absolute path must be specified by prepending an additional forward
    #  slash to the beginning of the path.
    #  ftp://user:password@ftp.example.com//readme.txt - This retrieves the
    #  readme.txt from the root directory when logging in as a specified
    #  user.
    #  SMTP
    #  The path part of a SMTP request specifies the host name to present
    #  during communication with the mail server. If the path is omitted
    #  then libcurl will attempt to resolve the local computer's host name.
    #  However, this may not return the fully qualified domain name that is
    #  required by some mail servers and specifying this path allows you to
    #  set an alternative name, such as your machine's fully qualified
    #  domain name, which you might have obtained from an external function
    #  such as gethostname or getaddrinfo.
    #  smtp://mail.example.com - This connects to the mail server at
    #  example.com and sends your local computer's host name in the HELO /
    #  EHLO command.
    #  smtp://mail.example.com/client.example.com - This will send
    #  client.example.com in the HELO / EHLO command to the mail server at
    #  example.com.
    #  POP3
    #  The path part of a POP3 request specifies the mailbox (message) to
    #  retrieve. If the mailbox is not specified then a list of waiting
    #  messages is returned instead.
    #  pop3://user:password@mail.example.com - This lists the available
    #  messages pop3://user:password@mail.example.com/1 - This retrieves the
    #  first message
    #  SCP
    #  The path part of a SCP request specifies the file to retrieve and
    #  from what directory. The file part may not be omitted. The file is
    #  taken as an absolute path from the root directory on the server. To
    #  specify a path relative to the user's home directory on the server,
    #  prepend ~/ to the path portion. If the user name is not embedded in
    #  the URL, it can be set with the CURLOPT_USERPWD or CURLOPT_USERNAME
    #  option.
    #  scp://user@example.com/etc/issue - This specifies the file /etc/issue
    #  scp://example.com/~/my-file - This specifies the file my-file in the
    #  user's home directory on the server
    #  SFTP
    #  The path part of a SFTP request specifies the file to retrieve and
    #  from what directory. If the file part is omitted then libcurl
    #  downloads the directory listing for the directory specified. If the
    #  path ends in a / then a directory listing is returned instead of a
    #  file. If the path is omitted entirely then the directory listing for
    #  the root / home directory will be returned. If the user name is not
    #  embedded in the URL, it can be set with the CURLOPT_USERPWD or
    #  CURLOPT_USERNAME option.
    #  sftp://user:password@example.com/etc/issue - This specifies the file
    #  /etc/issue
    #  sftp://user@example.com/~/my-file - This specifies the file my-file
    #  in the user's home directory
    #  sftp://ssh.example.com/~/Documents/ - This requests a directory
    #  listing of the Documents directory under the user's home directory
    #  LDAP
    #  The path part of a LDAP request can be used to specify the:
    #  Distinguished Name, Attributes, Scope, Filter and Extension for a
    #  LDAP search. Each field is separated by a question mark and when that
    #  field is not required an empty string with the question mark
    #  separator should be included.
    #  ldap://ldap.example.com/o=My%20Organisation - This will perform a
    #  LDAP search with the DN as My Organisation.
    #  ldap://ldap.example.com/o=My%20Organisation?postalAddress - This will
    #  perform the same search but will only return postalAddress attributes.
    #  ldap://ldap.example.com/?rootDomainNamingContext - This specifies an
    #  empty DN and requests information about the rootDomainNamingContext
    #  attribute for an Active Directory server.
    #  For more information about the individual components of a LDAP URL
    #  please see RFC 4516.
    #  NOTES
    #  Starting with version 7.20.0, the fragment part of the URI will not
    #  be sent as part of the path, which was previously the case.
    #  CURLOPT_URL is the only option that must be set before
    #  curl_easy_perform(3) is called.
    #  CURLOPT_PROTOCOLS can be used to limit what protocols libcurl will
    #  use for this transfer, independent of what libcurl has been compiled
    #  to support. That may be useful if you accept the URL from an external
    #  source and want to limit the accessibility.
    # @option options :useragent [String]
    #  Pass a pointer to a zero terminated string as parameter. It will be
    #  used to set the User-Agent: header in the http request sent to the
    #  remote server. This can be used to fool servers or scripts. You can
    #  also set any custom header with CURLOPT_HTTPHEADER.
    # @option options :userpwd [String]
    #  Pass a char * as parameter, which should be [user name]:[password] to
    #  use for the connection. Use CURLOPT_HTTPAUTH to decide the
    #  authentication method.
    #  When using NTLM, you can set the domain by prepending it to the user
    #  name and separating the domain and name with a forward (/) or
    #  backward slash (\). Like this: "domain/user:password" or
    #  "domain\user:password". Some HTTP servers (on Windows) support this
    #  style even for Basic authentication.
    #  When using HTTP and CURLOPT_FOLLOWLOCATION, libcurl might perform
    #  several requests to possibly different hosts. libcurl will only send
    #  this user and password information to hosts using the initial host
    #  name (unless CURLOPT_UNRESTRICTED_AUTH is set), so if libcurl follows
    #  locations to other hosts it will not send the user and password to
    #  those. This is enforced to prevent accidental information leakage.
    # @option options :verbose [Boolean]
    #  Set the parameter to 1 to get the library to display a lot of verbose
    #  information about its operations. Very useful for libcurl and/or
    #  protocol debugging and understanding. The verbose information will be
    #  sent to stderr, or the stream set with CURLOPT_STDERR.
    #  You hardly ever want this set in production use, you will almost
    #  always want this when you debug/report problems. Another neat option
    #  for debugging is the CURLOPT_DEBUGFUNCTION.
    #
    # @return [ Easy ] A new Easy.
    #
    # @see http://curl.haxx.se/libcurl/c/curl_easy_setopt.html
    #
    # @api public
    def initialize(options = {})
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      set_attributes(options)
      set_callbacks
    end

    # Set given options.
    #
    # @example Set options.
    #   easy.set_attributes(options)
    #
    # @param [ Hash ] options The options.
    #
    # @raise InvalidOption
    #
    # @see initialize
    #
    # @api private
    def set_attributes(options)
      options.each_pair do |key, value|
        unless respond_to?("#{key}=")
          raise Errors::InvalidOption.new(key)
        end
        method("#{key}=").call(value)
      end
    end

    # Reset easy. This means resetting all options and instance variables.
    # Also the easy handle is resetted.
    #
    # @example Reset.
    #   easy.reset
    def reset
      @url = nil
      @hash = nil
      Curl.easy_reset(handle)
      set_callbacks
    end

    # Url escapes the value.
    #
    # @example Url escape.
    #   easy.escape(value)
    #
    # @param [ String ] value The value to escape.
    #
    # @return [ String ] The escaped value.
    #
    # @api private
    def escape(value)
      Curl.easy_escape(handle, value, 0)
    end

    # Returns the informations available through libcurl as
    # a hash.
    #
    # @return [ Hash ] The informations hash.
    def to_hash
      return @hash if defined?(@hash) && @hash
      @hash = {
        :return_code => return_code,
        :response_headers => response_headers,
        :response_body => response_body
      }
      Easy::Informations::AVAILABLE_INFORMATIONS.keys.each do |info|
        @hash[info] = method(info).call
      end
      @hash
    end

    # Return pretty log out.
    #
    # @example Return log out.
    #   easy.log_inspect
    #
    # @return [ String ] The log out.
    def log_inspect
      hash = {
        :url => url,
        :response_code => response_code,
        :return_code => return_code,
        :total_time => total_time
      }
      "EASY #{hash.map{|k, v| "#{k}=#{v}"}.flatten.join(' ')}"
    end
  end
end
