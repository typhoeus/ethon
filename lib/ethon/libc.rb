module Ethon
  module Libc
    extend FFI::Library
    ffi_lib 'c'
    attach_function :getdtablesize, [], :int
    attach_function :free, [:pointer], :void
  end
end
