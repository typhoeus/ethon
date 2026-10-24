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
      value = Etc.sysconf(Etc::SC_OPEN_MAX)
      return value if value && value > 0

      Process.getrlimit(:NOFILE).first
    rescue NameError, NotImplementedError
      Process.getrlimit(:NOFILE).first
    end

    # Size of the native fd_set, rounded up to whole longs. An unaligned
    # ETHON_FD_SIZE would make select write past the Ruby-side struct.
    def self.fd_size(value = ENV['ETHON_FD_SIZE'])
      value = value.to_s
      size = if value.empty?
        [open_max, 65_536].min
      else
        begin
          Integer(value, 10)
        rescue ArgumentError, TypeError
          raise ArgumentError, "ETHON_FD_SIZE must be a positive integer"
        end
      end
      raise ArgumentError, "ETHON_FD_SIZE must be a positive integer" unless size > 0

      word = FFI::Type::LONG.size
      ((size + word - 1) / word) * word
    end

    unless windows?
      attach_function :free, [:pointer], :void
    end
  end
end
