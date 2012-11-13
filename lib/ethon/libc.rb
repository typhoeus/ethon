module Ethon
  module Libc
    extend FFI::Library
    ffi_lib 'c'

    # :nodoc:
    def self.windows?
      !(RbConfig::CONFIG['host_os'] !~ /mingw|mswin|bccwin/)
    end

    unless windows?
      attach_function :getdtablesize, [], :int
      attach_function :free, [:pointer], :void
    end
  end
end
