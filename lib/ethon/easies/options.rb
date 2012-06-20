module Ethon
  module Easies

    # This module contains the logic and knowledge about the
    # available options on easy.
    module Options

      # :nodoc:
      def self.included(base)
        base.extend ClassMethods
        base.const_set(:AVAILABLE_OPTIONS, [
          :httppost, :put, :httpget, :nobody, :upload, :customrequest,
          :cainfo, :capath, :connecttimeout,
          :followlocation, :httpauth, :infilesize, :interface,
          :maxredirs, :nosignal, :postfieldsize, :copypostfields, :proxy,
          :proxyauth, :proxytype, :timeout, :readdata, :sslcert, :ssl_verifypeer, :ssl_verifyhost,
          :sslcerttype, :sslkey, :sslkeytype, :sslversion,
          :url, :useragent, :userpwd, :verbose, :readfunction
        ])
        base.send(:attr_accessor, *Ethon::Easy::AVAILABLE_OPTIONS)
      end

      module ClassMethods # :nodoc:

        # Return the available options.
        #
        # @example Return the available options.
        #   easy.available_options
        #
        # @return [ Array ]  The available options.
        def available_options
          Ethon::Easy::AVAILABLE_OPTIONS
        end

        # Return the options which need to set as 0 or 1 for easy.
        #
        # @example Return the bool options.
        #   easy.bool_options
        #
        # @return [ Array ] The bool options.
        def bool_options
          [
            :followlocation, :nosignal, :ssl_verifypeer, :ssl_verifyhost,
            :verbose, :httpget, :nobody, :upload
          ]
        end

        # Return the options which are an enum for easy.
        #
        # @example Return the enum options.
        #   easy.enum_options
        #
        # @return [ Hash ] The enum options.
        def enum_options
          { :httpauth => Curl::Auth }
        end

        # Return the options which need to set as an integer for easy.
        #
        # @example Return the int options.
        #   easy.int_options
        #
        # @return [ Array ] The int options.
        def int_options
          [ :connecttimeout, :infilesize, :maxredirs, :postfieldsize, :timeout ]
        end
      end

      # Set specified options on easy handle.
      #
      # @example Set options.
      #   easy.set_options
      def set_options
        self.class.available_options.each do |option|
          value = value_for(option)
          next if value.nil?

          Curl.set_option(option, value, handle)
        end
      end

      # Return the value to set to easy handle. It is converted with the help
      # of bool_options, enum_options and int_options.
      #
      # @example Return casted the value.
      #   easy.value_for(:verbose)
      #
      # @return [ Object ] The casted value.
      def value_for(option)
        value = method(option).call
        return nil if value.nil?

        if self.class.bool_options.include?(option)
          value ? 1 : 0
        elsif self.class.enum_options.key?(option)
          self.class.enum_options[option][value]
        elsif self.class.int_options.include?(option)
          value.to_i
        elsif value.is_a?(::String)
          Util.escape_zero_byte(value)
        else
          value
        end
      end
    end
  end
end
