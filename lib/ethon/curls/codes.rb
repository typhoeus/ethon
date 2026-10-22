# frozen_string_literal: true
module Ethon
  module Curls # :nodoc:

    # This module contains all easy and
    # multi return codes.
    module Codes

      # Libcurl error codes, refer
      # https://github.com/bagder/curl/blob/master/include/curl/curl.h for details
      def easy_codes
        [
          :ok,
          :unsupported_protocol,
          :failed_init,
          :url_malformat,
          :not_built_in,
          :couldnt_resolve_proxy,
          :couldnt_resolve_host,
          :couldnt_connect,
          :ftp_weird_server_reply, # CURLE_WEIRD_SERVER_REPLY since 7.51.0
          :remote_access_denied,
          :ftp_accept_failed,
          :ftp_weird_pass_reply,
          :ftp_accept_timeout,
          :ftp_weird_pasv_reply,
          :ftp_weird_227_format,
          :ftp_cant_get_host,
          :http2,
          :ftp_couldnt_set_type,
          :partial_file,
          :ftp_couldnt_retr_file,
          :obsolete20,
          :quote_error,
          :http_returned_error,
          :write_error,
          :obsolete24,
          :upload_failed,
          :read_error,
          :out_of_memory,
          :operation_timedout,
          :obsolete29,
          :ftp_port_failed,
          :ftp_couldnt_use_rest,
          :obsolete32,
          :range_error,
          :http_post_error, # CURLE_OBSOLETE34 since 7.56.0
          :ssl_connect_error,
          :bad_download_resume,
          :file_couldnt_read_file,
          :ldap_cannot_bind,
          :ldap_search_failed,
          :obsolete40,
          :function_not_found, # CURLE_OBSOLETE41 since 7.53.0
          :aborted_by_callback,
          :bad_function_argument,
          :obsolete44,
          :interface_failed,
          :obsolete46,
          :too_many_redirects ,
          :unknown_option,
          :telnet_option_syntax, # CURLE_SETOPT_OPTION_SYNTAX since 7.78.0
          :obsolete50,
          :obsolete51,
          :got_nothing,
          :ssl_engine_notfound,
          :ssl_engine_setfailed,
          :send_error,
          :recv_error,
          :obsolete57,
          :ssl_certproblem,
          :ssl_cipher,
          :peer_failed_verification,
          :bad_content_encoding,
          :ldap_invalid_url, # CURLE_OBSOLETE62 since 7.82.0
          :filesize_exceeded,
          :use_ssl_failed,
          :send_fail_rewind,
          :ssl_engine_initfailed,
          :login_denied,
          :tftp_notfound,
          :tftp_perm,
          :remote_disk_full,
          :tftp_illegal,
          :tftp_unknownid,
          :remote_file_exists,
          :tftp_nosuchuser,
          :conv_failed, # CURLE_OBSOLETE75 since 7.82.0
          :conv_reqd, # CURLE_OBSOLETE76 since 7.82.0
          :ssl_cacert_badfile,
          :remote_file_not_found,
          :ssh,
          :ssl_shutdown_failed,
          :again,
          :ssl_crl_badfile,
          :ssl_issuer_error,
          :ftp_pret_failed,
          :rtsp_cseq_error,
          :rtsp_session_error,
          :ftp_bad_file_list,
          :chunk_failed,
          :no_connection_available,
          :ssl_pinnedpubkeynotmatch,
          :ssl_invalidcertstatus,
          :http2_stream,
          :recursive_api_call,
          :auth_error,
          :http3,
          :quic_connect_error,
          :proxy,
          :ssl_clientcert,
          :unrecoverable_poll,
          :too_large,
          :ech_required,
          :last
        ]
      end

      # Curl-Multi socket error codes, refer
      # https://github.com/bagder/curl/blob/master/include/curl/multi.h for details
      def multi_codes
        [
          :call_multi_perform, -1,
          :ok,
          :bad_handle,
          :bad_easy_handle,
          :out_of_memory,
          :internal_error,
          :bad_socket,
          :unknown_option,
          :last
        ]
      end
    end
  end
end
