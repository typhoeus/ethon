module Ethon
  class Multi

    # This module contains the logic and knowledge about the
    # available options on multi.
    module Options

      # Sets maxconnects option.
      #
      # @example Set maxconnects option.
      #   easy.maxconnects = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def maxconnects=(value)
        Curl.set_option(:maxconnects, value_for(value, :int), handle)
      end

      # Sets pipelining option.
      #
      # @example Set pipelining option.
      #   easy.pipelining = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def pipelining=(value)
        Curl.set_option(:pipelining, value_for(value, :bool), handle)
      end

      # Sets socketdata option.
      #
      # @example Set socketdata option.
      #   easy.socketdata = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def socketdata=(value)
        Curl.set_option(:socketdata, value_for(value, :string), handle)
      end

      # Sets socketfunction option.
      #
      # @example Set socketfunction option.
      #   easy.socketfunction = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def socketfunction=(value)
        Curl.set_option(:socketfunction, value_for(value, :string), handle)
      end

      # Sets timerdata option.
      #
      # @example Set timerdata option.
      #   easy.timerdata = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def timerdata=(value)
        Curl.set_option(:timerdata, value_for(value, :string), handle)
      end

      # Sets timerfunction option.
      #
      # @example Set timerfunction option.
      #   easy.timerfunction = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def timerfunction=(value)
        Curl.set_option(:timerfunction, value_for(value, :string), handle)
      end

      private

      # Return the value to set to multi handle. It is converted with the help
      # of bool_options, enum_options and int_options.
      #
      # @example Return casted the value.
      #   multi.value_for(:verbose)
      #
      # @return [ Object ] The casted value.
      def value_for(value, type, option = nil)
        return nil if value.nil?

        if type == :bool
          value ? 1 : 0
        elsif type == :int
          value.to_i
        elsif value.is_a?(String)
          Ethon::Easy::Util.escape_zero_byte(value)
        else
          value
        end
      end
    end
  end
end
