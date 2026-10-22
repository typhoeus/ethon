# frozen_string_literal: true
require 'etc'

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

    def self.open_max
      Etc.sysconf(Etc::SC_OPEN_MAX) || Process.getrlimit(:NOFILE).first
    rescue NameError, NotImplementedError
      Process.getrlimit(:NOFILE).first
    end

    unless windows?
      attach_function :free, [:pointer], :void
    end
  end
end
