# frozen_string_literal: true
module Ethon
  class Multi

    # This module contains the logic and knowledge about the
    # available options on multi.
    module Options

      # Sets max_total_connections option.
      #
      # @example Set max_total_connections option.
      #   multi.max_total_connections = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def max_total_connections=(value)
        Curl.set_option(:max_total_connections, value_for(value, :int, :max_total_connections), handle, :multi)
      end

      # Sets max_concurrent_streams option.
      #
      # @example Set max_concurrent_streams option.
      #   multi.max_concurrent_streams = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def max_concurrent_streams=(value)
        Curl.set_option(:max_concurrent_streams, value_for(value, :int, :max_concurrent_streams), handle, :multi)
      end

      # Sets maxconnects option.
      #
      # An explicit value also disables the automatic sizing described in
      # #raise_default_maxconnects.
      #
      # @example Set maxconnects option.
      #   multi.maxconnects = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def maxconnects=(value)
        @maxconnects_configured = true unless value.nil?
        set_maxconnects(value)
      end

      # Sets max_host_connections option.
      #
      # @example Set max_host_connections option.
      #   multi.max_host_connections = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def max_host_connections=(value)
        Curl.set_option(:max_host_connections, value_for(value, :int, :max_host_connections), handle, :multi)
      end

      # Sets max_pipeline_length option.
      #
      # @example Set max_pipeline_length option.
      #   multi.max_pipeline_length = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def max_pipeline_length=(value)
        Curl.set_option(:max_pipeline_length, value_for(value, :int, :max_pipeline_length), handle, :multi)
      end

      # Sets content_length_penalty_size option.
      #
      # @example Set content_length_penalty_size option.
      #   multi.content_length_penalty_size = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def content_length_penalty_size=(value)
        Curl.set_option(:content_length_penalty_size, value, handle, :multi)
      end

      # Sets chunk_length_penalty_size option.
      #
      # @example Set chunk_length_penalty_size option.
      #   multi.chunk_length_penalty_size = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def chunk_length_penalty_size=(value)
        Curl.set_option(:chunk_length_penalty_size, value, handle, :multi)
      end

      # Sets pipelining option.
      #
      # @example Set pipelining option.
      #   multi.pipelining = $value
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def pipelining=(value)
        Curl.set_option(:pipelining, value_for(value, :int, :pipelining), handle, :multi)
      end

      # Sets socketdata option.
      #
      # @example Set socketdata option.
      #   multi.socketdata = $value
      #
      # @param [ FFI::Pointer, nil ] value The value to set.
      #
      # @return [ void ]
      def socketdata=(value)
        Curl.set_option(:socketdata, value_for(value, :string), handle, :multi)
      end

      # Sets socketfunction option.
      #
      # @example Set socketfunction option.
      #   multi.socketfunction = $value
      #
      # @param [ Proc, nil ] value The value to set.
      #
      # @return [ void ]
      def socketfunction=(value)
        Curl.set_option(:socketfunction, value_for(value, :string), handle, :multi)
        retain_callback(:socketfunction, value)
        value
      end

      # Sets timerdata option.
      #
      # @example Set timerdata option.
      #   multi.timerdata = $value
      #
      # @param [ FFI::Pointer, nil ] value The value to set.
      #
      # @return [ void ]
      def timerdata=(value)
        Curl.set_option(:timerdata, value_for(value, :string), handle, :multi)
      end

      # Sets timerfunction option.
      #
      # @example Set timerfunction option.
      #   multi.timerfunction = $value
      #
      # @param [ Proc, nil ] value The value to set.
      #
      # @return [ void ]
      def timerfunction=(value)
        Curl.set_option(:timerfunction, value_for(value, :string), handle, :multi)
        retain_callback(:timerfunction, value)
        value
      end

      private

      # Raise the default connection cache size to twice the largest number
      # of easy handles ever attached at once.
      #
      # libcurl derives its default from the number of handles attached when
      # a connection is returned. Ethon detaches each handle as soon as its
      # transfer finishes, so that number falls during a run and libcurl
      # closes connections that later requests could have reused.
      #
      # @param [ Integer ] count The number of attached handles after the
      #   pending add.
      #
      # @return [ void ]
      def raise_default_maxconnects(count)
        return if @maxconnects_configured
        return if count <= (@maxconnects_high_water ||= 0)

        @maxconnects_high_water = count
        set_maxconnects(2 * count)
      end

      def set_maxconnects(value)
        Curl.set_option(:maxconnects, value_for(value, :int, :maxconnects), handle, :multi)
      end

      def retain_callback(option, callback)
        if callback.nil?
          @procs.delete(option) if @procs
        else
          (@procs ||= {})[option] = callback
        end
        Curl::MultiHandle.retain_callback(handle, option, callback)
      end

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
          Ethon::Curls::Options.integer_value(option, value)
        elsif value.is_a?(String)
          Ethon::Easy::Util.escape_zero_byte(value)
        else
          value
        end
      end

    end
  end
end
