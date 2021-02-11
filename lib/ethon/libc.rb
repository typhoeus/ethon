# frozen_string_literal: true
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

    unless windows?
      fcg = FFI::ConstGenerator.new do |gen|
        gen.include 'unistd.h'
        %w[
          _SC_OPEN_MAX
        ].each do |const|
          ruby_name = const.sub(/^_SC_/, '').downcase.to_sym
          gen.const(const, "%d", nil, ruby_name, &:to_i)
        end
      end

      CONF = enum(*fcg.constants.map{|_, const|
        [const.ruby_name, const.converted_value]
      }.flatten)

      attach_function :sysconf, [CONF], :long
      attach_function :free, [:pointer], :void
    end
  end
end
