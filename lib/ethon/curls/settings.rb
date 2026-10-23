# frozen_string_literal: true
module Ethon
  module Curl
    if Curl.windows?
      typedef :size_t, :curl_socket_t
    else
      typedef :int, :curl_socket_t
    end

    callback :callback, [:pointer, :size_t, :size_t, :pointer], :size_t
    callback :socket_callback, [:pointer, :curl_socket_t, :poll_action, :pointer, :pointer], :multi_code
    callback :timer_callback, [:pointer, :long, :pointer], :multi_code
    callback :debug_callback, [:pointer, :debug_info_type, :pointer, :size_t, :pointer], :int
    # CURLOPT_PROGRESSFUNCTION uses doubles, while CURLOPT_XFERINFOFUNCTION uses
    # curl_off_t. They are not ABI-compatible on all platforms.
    callback :progress_callback, [:pointer, :double, :double, :double, :double], :int
    callback :xferinfo_callback, [:pointer, :long_long, :long_long, :long_long, :long_long], :int
    ffi_lib_flags :now, :global
    ffi_lib ENV.fetch('ETHON_CURL_LIBS', 'libcurl,libcurl.so.4,libcurl-4,libcurl-x64,libcurl-arm64').split(',')
  end
end
