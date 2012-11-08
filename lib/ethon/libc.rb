module Ethon
  module Libc
    extend FFI::Library
    ffi_lib 'c'
    attach_function :getdtablesize, [], :int
  end
end
