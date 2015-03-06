module Ethon

  # FFI Wrapper module for Libc.
  #
  # @api private
  module Libc
    extend FFI::Library
    ffi_lib 'c'

    # :nodoc:
    def self.windows?
      Gem.win_platform?
    end

    def self.ffi_fclose(fh)
      retv = fclose(fh)
      fail SystemCallError.new(FFI.errno) unless retv == 0
    end

    def self.ffi_fopen(path, mode)
      fh = fopen(path, mode)
      fail SystemCallError.new(FFI.errno), path if fh == nil
      return fh
    end

    unless windows?
      attach_function :getdtablesize, [], :int
      attach_function :free, [:pointer], :void
      attach_function :fopen, [:string, :string], :pointer
      attach_function :fclose, [:pointer], :int
    end
  end
end
