# frozen_string_literal: true
require 'spec_helper'

describe "curl 8.7.1 option surface" do
  TYPE_BASE = {
    :long => 0,
    :objectpoint => 10000,
    :functionpoint => 20000,
    :off_t => 30000,
    :blob => 40000
  }.freeze

  ETHON_TYPE_BASE = {
    :int => :long,
    :bool => :long,
    :enum => :long,
    :bitmask => :long,
    :string => :objectpoint,
    :curl_slist => :objectpoint,
    :ffipointer => :objectpoint,
    :dontuse_callback => :functionpoint,
    :off_t => :off_t,
    :blob => :blob
  }.freeze

  NEW_OPTIONS = {
    :curlu => [:ffipointer, 282],
    :abstract_unix_socket => [:string, 264],
    :altsvc => [:string, 287],
    :altsvc_ctrl => [:bitmask, 286],
    :aws_sigv4 => [:string, 305],
    :ca_cache_timeout => [:int, 321],
    :cainfo_blob => [:blob, 309],
    :connect_to => [:curl_slist, 243],
    :default_protocol => [:string, 238],
    :disallow_username_in_url => [:bool, 278],
    :dns_local_ip6 => [:string, 223],
    :doh_ssl_verifyhost => [:int, 307],
    :doh_ssl_verifypeer => [:bool, 306],
    :doh_ssl_verifystatus => [:bool, 308],
    :doh_url => [:string, 279],
    :expect_100_timeout_ms => [:int, 227],
    :happy_eyeballs_timeout_ms => [:int, 271],
    :haproxy_client_ip => [:string, 323],
    :haproxyprotocol => [:bool, 274],
    :headeropt => [:enum, 229],
    :hsts => [:string, 300],
    :hsts_ctrl => [:bitmask, 299],
    :hstsreaddata => [:ffipointer, 302],
    :hstsreadfunction => [:dontuse_callback, 301],
    :hstswritedata => [:ffipointer, 304],
    :hstswritefunction => [:dontuse_callback, 303],
    :http09_allowed => [:bool, 285],
    :issuercert_blob => [:blob, 295],
    :keep_sending_on_error => [:bool, 245],
    :login_options => [:string, 224],
    :mail_rcpt_allowfails => [:bool, 290],
    :maxage_conn => [:int, 288],
    :maxlifetime_conn => [:int, 314],
    :mime_options => [:bitmask, 315],
    :mimepost => [:ffipointer, 269],
    :prereqdata => [:ffipointer, 313],
    :prereqfunction => [:dontuse_callback, 312],
    :protocols_str => [:string, 318],
    :proxy_cainfo_blob => [:blob, 310],
    :proxy_issuercert_blob => [:blob, 297],
    :proxy_service_name => [:string, 235],
    :proxy_sslcert_blob => [:blob, 293],
    :proxy_sslkey_blob => [:blob, 294],
    :proxy_tls13_ciphers => [:string, 277],
    :proxyheader => [:curl_slist, 228],
    :quick_exit => [:bool, 322],
    :redir_protocols_str => [:string, 319],
    :request_target => [:string, 266],
    :resolver_start_data => [:ffipointer, 273],
    :resolver_start_function => [:dontuse_callback, 272],
    :sasl_authzid => [:string, 289],
    :server_response_timeout_ms => [:int, 324],
    :service_name => [:string, 236],
    :socks5_auth => [:bitmask, 267],
    :ssh_compression => [:bool, 268],
    :ssh_host_public_key_sha256 => [:string, 311],
    :ssh_hostkeydata => [:ffipointer, 317],
    :ssh_hostkeyfunction => [:dontuse_callback, 316],
    :ssl_ec_curves => [:string, 298],
    :ssl_enable_alpn => [:bool, 226],
    :ssl_enable_npn => [:bool, 225],
    :ssl_falsestart => [:bool, 233],
    :ssl_verifystatus => [:bool, 232],
    :sslcert_blob => [:blob, 291],
    :sslkey_blob => [:blob, 292],
    :stream_depends => [:ffipointer, 240],
    :stream_depends_e => [:ffipointer, 241],
    :stream_weight => [:int, 239],
    :suppress_connect_headers => [:bool, 265],
    :tftp_no_options => [:bool, 242],
    :timevalue_large => [:off_t, 270],
    :tls13_ciphers => [:string, 276],
    :trailerdata => [:ffipointer, 284],
    :trailerfunction => [:dontuse_callback, 283],
    :upkeep_interval_ms => [:int, 281],
    :upload_buffersize => [:int, 280],
    :ws_options => [:bitmask, 320],
    :xoauth2_bearer => [:string, 220]
  }.freeze

  NEW_OPTIONS.each do |name, (type, number)|
    it "defines #{name}" do
      option = Ethon::Curl.easy_options(nil)[name]

      expect(option).not_to be_nil
      expect(option[:type]).to eq(type)
      expect(option[:opt]).to eq(TYPE_BASE.fetch(ETHON_TYPE_BASE.fetch(type)) + number)
    end
  end

  it "adds max_concurrent_streams to multi options" do
    expect(Ethon::Curl.multi_options(nil)[:max_concurrent_streams]).to include(
      :type => :int,
      :opt => 16
    )
  end
end
