module Ethon
  class Easy

    # This module contains the logic and knowledge about the
    # available options on easy.
    #
    # @api private
    module Options

      attr_reader :url

      # Sets cainfo option.
      #
      # @example Set cainfo option.
      #   easy.cainfo = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def cainfo=(value)
        Curl.set_option(:cainfo, value_for(value, :string), handle)
      end

      # Sets capath option.
      #
      # @example Set capath option.
      #   easy.capath = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def capath=(value)
        Curl.set_option(:capath, value_for(value, :string), handle)
      end

      # Sets connecttimeout option.
      #
      # @example Set connecttimeout option.
      #   easy.connecttimeout = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def connecttimeout=(value)
        Curl.set_option(:connecttimeout, value_for(value, :int), handle)
      end

      # Sets connecttimeout_ms option.
      #
      # @example Set connecttimeout_ms option.
      #   easy.connecttimeout_ms = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def connecttimeout_ms=(value)
        Curl.set_option(:connecttimeout_ms, value_for(value, :int), handle)
      end

      # Sets copypostfields option.
      #
      # @example Set copypostfields option.
      #   easy.copypostfields = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def copypostfields=(value)
        Curl.set_option(:copypostfields, value_for(value, :string), handle)
      end

      # Sets customrequest option.
      #
      # @example Set customrequest option.
      #   easy.customrequest = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def customrequest=(value)
        Curl.set_option(:customrequest, value_for(value, :string), handle)
      end

      # Sets dns_cache_timeout option.
      #
      # @example Set dns_cache_timeout option.
      #   easy.dns_cache_timeout = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def dns_cache_timeout=(value)
        Curl.set_option(:dns_cache_timeout, value_for(value, :int), handle)
      end

      # Sets followlocation option.
      #
      # @example Set followlocation option.
      #   easy.followlocation = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def followlocation=(value)
        Curl.set_option(:followlocation, value_for(value, :bool), handle)
      end

      # Sets forbid_reuse option.
      #
      # @example Set forbid_reuse option.
      #   easy.forbid_reuse = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def forbid_reuse=(value)
        Curl.set_option(:forbid_reuse, value_for(value, :bool), handle)
      end

      # Sets httpauth option.
      #
      # @example Set httpauth option.
      #   easy.httpauth = $value
      #
      # @param [ $type_doc ] value The value to set.
      #
      # @return [ void ]
      def httpauth=(value)
        Curl.set_option(:httpauth, value_for(value, :enum, :httpauth), handle)
      end

      # Sets httpget option.
      #
      # @example Set httpget option.
      #   easy.httpget = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def httpget=(value)
        Curl.set_option(:httpget, value_for(value, :bool), handle)
      end

      # Sets httppost option.
      #
      # @example Set httppost option.
      #   easy.httppost = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def httppost=(value)
        Curl.set_option(:httppost, value_for(value, :string), handle)
      end

      # Sets infilesize option.
      #
      # @example Set infilesize option.
      #   easy.infilesize = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def infilesize=(value)
        Curl.set_option(:infilesize, value_for(value, :int), handle)
      end

      # Sets interface option.
      #
      # @example Set interface option.
      #   easy.interface = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def interface=(value)
        Curl.set_option(:interface, value_for(value, :string), handle)
      end

      # Sets keypasswd option.
      #
      # @example Set keypasswd option.
      #   easy.keypasswd = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def keypasswd=(value)
        Curl.set_option(:keypasswd, value_for(value, :string), handle)
      end

      # Sets maxredirs option.
      #
      # @example Set maxredirs option.
      #   easy.maxredirs = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def maxredirs=(value)
        Curl.set_option(:maxredirs, value_for(value, :int), handle)
      end

      # Sets nobody option.
      #
      # @example Set nobody option.
      #   easy.nobody = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def nobody=(value)
        Curl.set_option(:nobody, value_for(value, :bool), handle)
      end

      # Sets nosignal option.
      #
      # @example Set nosignal option.
      #   easy.nosignal = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def nosignal=(value)
        Curl.set_option(:nosignal, value_for(value, :bool), handle)
      end

      # Sets postfieldsize option.
      #
      # @example Set postfieldsize option.
      #   easy.postfieldsize = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def postfieldsize=(value)
        Curl.set_option(:postfieldsize, value_for(value, :int), handle)
      end

      # Sets proxy option.
      #
      # @example Set proxy option.
      #   easy.proxy = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def proxy=(value)
        Curl.set_option(:proxy, value_for(value, :string), handle)
      end

      # Sets proxyauth option.
      #
      # @example Set proxyauth option.
      #   easy.proxyauth = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def proxyauth=(value)
        Curl.set_option(:proxyauth, value_for(value, :string), handle)
      end

      # Sets proxyport option.
      #
      # @example Set proxyport option.
      #   easy.proxyport = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def proxyport=(value)
        Curl.set_option(:proxyport, value_for(value, :int), handle)
      end

      # Sets proxytype option.
      #
      # @example Set proxytype option.
      #   easy.proxytype = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def proxytype=(value)
        Curl.set_option(:proxytype, value_for(value, :string), handle)
      end

      # Sets proxyuserpwd option.
      #
      # @example Set proxyuserpwd option.
      #   easy.proxyuserpwd = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def proxyuserpwd=(value)
        Curl.set_option(:proxyuserpwd, value_for(value, :string), handle)
      end

      # Sets readdata option.
      #
      # @example Set readdata option.
      #   easy.readdata = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def readdata=(value)
        Curl.set_option(:readdata, value_for(value, :string), handle)
      end

      # Sets readfunction option.
      #
      # @example Set readfunction option.
      #   easy.readfunction = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def readfunction=(value)
        Curl.set_option(:readfunction, value_for(value, :string), handle)
      end

      # Sets ssl_verifyhost option.
      #
      # @example Set ssl_verifyhost option.
      #   easy.ssl_verifyhost = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def ssl_verifyhost=(value)
        Curl.set_option(:ssl_verifyhost, value_for(value, :int), handle)
      end

      # Sets ssl_verifypeer option.
      #
      # @example Set ssl_verifypeer option.
      #   easy.ssl_verifypeer = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def ssl_verifypeer=(value)
        Curl.set_option(:ssl_verifypeer, value_for(value, :bool), handle)
      end

      # Sets sslcert option.
      #
      # @example Set sslcert option.
      #   easy.sslcert = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslcert=(value)
        Curl.set_option(:sslcert, value_for(value, :string), handle)
      end

      # Sets sslcerttype option.
      #
      # @example Set sslcerttype option.
      #   easy.sslcerttype = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslcerttype=(value)
        Curl.set_option(:sslcerttype, value_for(value, :string), handle)
      end

      # Sets sslkey option.
      #
      # @example Set sslkey option.
      #   easy.sslkey = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslkey=(value)
        Curl.set_option(:sslkey, value_for(value, :string), handle)
      end

      # Sets sslkeytype option.
      #
      # @example Set sslkeytype option.
      #   easy.sslkeytype = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def sslkeytype=(value)
        Curl.set_option(:sslkeytype, value_for(value, :string), handle)
      end

      # Sets sslversion option.
      #
      # @example Set sslversion option.
      #   easy.sslversion = $value
      #
      # @param [ $type_doc ] value The value to set.
      #
      # @return [ void ]
      def sslversion=(value)
        Curl.set_option(:sslversion, value_for(value, :enum, :sslversion), handle)
      end

      # Sets timeout option.
      #
      # @example Set timeout option.
      #   easy.timeout = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def timeout=(value)
        Curl.set_option(:timeout, value_for(value, :int), handle)
      end

      # Sets timeout_ms option.
      #
      # @example Set timeout_ms option.
      #   easy.timeout_ms = 1
      #
      # @param [ Integer ] value The value to set.
      #
      # @return [ void ]
      def timeout_ms=(value)
        Curl.set_option(:timeout_ms, value_for(value, :int), handle)
      end

      # Sets upload option.
      #
      # @example Set upload option.
      #   easy.upload = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def upload=(value)
        Curl.set_option(:upload, value_for(value, :bool), handle)
      end

      # Sets url option.
      #
      # @example Set url option.
      #   easy.url = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def url=(value)
        @url = value
        Curl.set_option(:url, value_for(value, :string), handle)
      end

      # Sets useragent option.
      #
      # @example Set useragent option.
      #   easy.useragent = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def useragent=(value)
        Curl.set_option(:useragent, value_for(value, :string), handle)
      end

      # Sets userpwd option.
      #
      # @example Set userpwd option.
      #   easy.userpwd = $value
      #
      # @param [ String ] value The value to set.
      #
      # @return [ void ]
      def userpwd=(value)
        Curl.set_option(:userpwd, value_for(value, :string), handle)
      end

      # Sets verbose option.
      #
      # @example Set verbose option.
      #   easy.verbose = true
      #
      # @param [ Boolean ] value The value to set.
      #
      # @return [ void ]
      def verbose=(value)
        Curl.set_option(:verbose, value_for(value, :bool), handle)
      end

      private

      # Return the value to set to easy handle. It is converted with the help
      # of bool_options, enum_options and int_options.
      #
      # @example Return casted the value.
      #   easy.value_for(:verbose)
      #
      # @param [ Symbol ] option The option to get the value from.
      #
      # @return [ Object ] The casted value.
      #
      # @raise [ Ethon::Errors::InvalidValue ] If specified option
      #   points to an enum and the value doen't correspond to
      #   the valid values.
      def value_for(value, type, option = nil)
        return nil if value.nil?

        if type == :bool
          value ? 1 : 0
        elsif type == :int
          value.to_i
        elsif type == :enum && option == :httpauth
          Curl::Auth.to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
        elsif type == :enum && option == :sslversion
          Curl::SSLVersion.to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
        elsif type == :enum && option == :proxytype
          Curl::Proxy.to_h.fetch(value) do
            raise Errors::InvalidValue.new(option, value)
          end
        elsif value.is_a?(String)
          Util.escape_zero_byte(value)
        else
          value
        end
      end
    end
  end
end
