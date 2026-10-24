# frozen_string_literal: true
module Ethon
  class Easy # :nodoc:

    # This module contains small helpers.
    #
    # @api private
    module Util

      # Escapes zero bytes in strings.
      #
      # @example Escape zero bytes.
      #   Util.escape_zero_byte("1\0")
      #   #=> "1\\0"
      #
      # @param [ Object ] value The value to escape.
      #
      # @return [ String, Object ] Escaped String if
      #   zero byte found, original object if not.
      def escape_zero_byte(value)
        return value unless value.to_s.include?(0.chr)
        value.to_s.gsub(0.chr, '\\\0')
      end

      # Rejects header lines libcurl would send verbatim as extra headers.
      #
      # @example Validate a header line.
      #   Util.validate_header_line(:headers, "X-Test: 1")
      #
      # @param [ Symbol ] option The option name used in the error.
      # @param [ String ] line The header line.
      #
      # @raise [ Errors::InvalidValue ] If the line contains CR, LF, or NUL.
      #
      # @return [ String ] The validated line.
      def validate_header_line(option, line)
        if line.include?("\r") || line.include?("\n") || line.include?("\0")
          raise Errors::InvalidValue.new(option, line)
        end

        line
      end

      extend self
    end
  end
end
