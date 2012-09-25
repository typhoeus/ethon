module Ethon
  class Multi

    # This module contains the logic and knowledge about the
    # available options on multi.
    module Options

      # :nodoc:
      #
      # @api private
      def self.included(base)
        base.extend ClassMethods
        base.const_set(:AVAILABLE_OPTIONS, [
          :socketfunction, :socketdata, :pipelining,
          :timerfunction, :timerdata, :maxconnects
        ])
        base.send(:attr_accessor, *Ethon::Multi::AVAILABLE_OPTIONS)
      end

      module ClassMethods # :nodoc:

        # Return the available options.
        #
        # @example Return the available options.
        #   multi.available_options
        #
        # @return [ Array ]  The available options.
        #
        # @api private
        def available_options
          Ethon::Multi::AVAILABLE_OPTIONS
        end

        # Return the options which need to set as 0 or 1 for multi.
        #
        # @example Return the bool options.
        #   multi.bool_options
        #
        # @return [ Array ] The bool options.
        #
        # @api private
        def bool_options
          [
            :pipelining
          ]
        end

        # Return the options which need to set as an integer for multi.
        #
        # @example Return the int options.
        #   multi.int_options
        #
        # @return [ Array ] The int options.
        #
        # @api private
        def int_options
          [
            :maxconnects
          ]
        end
      end

      # Set specified options on multi handle.
      #
      # @example Set options.
      #   multi.set_options
      #
      # @api private
      def set_options
        self.class.available_options.each do |option|
          Curl.set_option(option, value_for(option), handle, :multi)
        end
      end

      # Return the value to set to multi handle. It is converted with the help
      # of bool_options, enum_options and int_options.
      #
      # @example Return casted the value.
      #   multi.value_for(:verbose)
      #
      # @return [ Object ] The casted value.
      #
      # @api private
      def value_for(option)
        value = method(option).call
        return nil if value.nil?

        if self.class.bool_options.include?(option)
          value ? 1 : 0
        elsif self.class.int_options.include?(option)
          value.to_i
        else
          value
        end
      end
    end
  end
end
