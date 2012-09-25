module Ethon
  class Easy

    # This module contains the logic and knowledge about the
    # available options on easy.
    module Options

      # :nodoc:
      #
      # @api private
      def self.included(base)
        base.extend ClassMethods
        base.const_set(:AVAILABLE_OPTIONS, [
          :dns_cache_timeout, :httppost, :httpget, :nobody, :upload,
          :customrequest, :cainfo, :capath, :connecttimeout, :connecttimeout_ms,
          :forbid_reuse, :followlocation, :httpauth, :infilesize, :interface,
          :maxredirs, :nosignal, :postfieldsize, :copypostfields, :proxy,
          :proxyauth, :proxyport, :proxytype, :proxyuserpwd, :timeout, :timeout_ms,
          :readdata, :sslcert, :ssl_verifypeer, :ssl_verifyhost, :sslcerttype,
          :sslkey, :sslkeytype, :sslversion, :url, :useragent, :userpwd,
          :verbose, :readfunction
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
        #
        # @api private
        def available_options
          Ethon::Easy::AVAILABLE_OPTIONS
        end

        # Return the options which need to set as 0 or 1 for easy.
        #
        # @example Return the bool options.
        #   easy.bool_options
        #
        # @return [ Array ] The bool options.
        #
        # @api private
        def bool_options
          [
            :followlocation, :forbid_reuse, :nosignal, :ssl_verifypeer,
            :verbose, :httpget, :nobody, :upload
          ]
        end

        # Return the options which are an enum for easy.
        #
        # @example Return the enum options.
        #   easy.enum_options
        #
        # @return [ Hash ] The enum options.
        #
        # @api private
        def enum_options
          { :httpauth => Curl::Auth, :sslversion => Curl::SSLVersion }
        end

        # Return the options which need to set as an integer for easy.
        #
        # @example Return the int options.
        #   easy.int_options
        #
        # @return [ Array ] The int options.
        #
        # @api private
        def int_options
          [
            :connecttimeout, :connecttimeout_ms, :dns_cache_timeout, :infilesize, :maxredirs,
            :postfieldsize, :proxyport, :ssl_verifyhost, :timeout, :timeout_ms
          ]
        end
      end

      # Set specified options on easy handle.
      #
      # @example Set options.
      #   easy.set_options
      #
      # @api private
      def set_options
        self.class.available_options.each do |option|
          Curl.set_option(option, value_for(option), handle)
        end
      end

      # Return the value to set to easy handle. It is converted with the help
      # of bool_options, enum_options and int_options.
      #
      # @example Return casted the value.
      #   easy.value_for(:verbose)
      #
      # @return [ Object ] The casted value.
      #
      # @api private
      def value_for(option)
        value = method(option).call
        return nil if value.nil?

        if self.class.bool_options.include?(option)
          value ? 1 : 0
        elsif self.class.enum_options.key?(option)
          self.class.enum_options[option].to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
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
