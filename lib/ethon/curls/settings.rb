module Ethon
  module Curl
    callback :callback, [:pointer, :size_t, :size_t, :pointer], :size_t
    ffi_lib_flags :now, :global
    ffi_lib ['libcurl', 'libcurl.so.4']
  end
end
