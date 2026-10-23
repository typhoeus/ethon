# frozen_string_literal: true
module Ethon
  module Curl
    # CURLUPart values from curl/urlapi.h.
    UrlPart = enum(:url_part, [
      :url,
      :scheme,
      :user,
      :password,
      :options,
      :host,
      :port,
      :path,
      :query,
      :fragment,
      :zoneid
    ])

    # CURLUcode values from curl/urlapi.h.
    UrlCode = enum(:url_code, [
      :ok,
      :bad_handle,
      :bad_partpointer,
      :malformed_input,
      :bad_port_number,
      :unsupported_scheme,
      :urldecode,
      :out_of_memory,
      :user_not_allowed,
      :unknown_part,
      :no_scheme,
      :no_user,
      :no_password,
      :no_options,
      :no_host,
      :no_port,
      :no_query,
      :no_fragment,
      :no_zoneid,
      :bad_file_url,
      :bad_fragment,
      :bad_hostname,
      :bad_ipv6,
      :bad_login,
      :bad_password,
      :bad_path,
      :bad_query,
      :bad_scheme,
      :bad_slashes,
      :bad_user,
      :lacks_idn,
      :too_large,
      :last
    ])

    # CURLU_* flag bits from curl/urlapi.h.
    UrlFlags = bitmask(:url_flags, [
      nil,
      :default_port,
      :no_default_port,
      :default_scheme,
      :non_support_scheme,
      :path_as_is,
      :disallow_user,
      :urldecode,
      :urlencode,
      :appendquery,
      :guess_scheme,
      :no_authority,
      :allow_space,
      :punycode,
      :puny2idn
    ])
  end
end
