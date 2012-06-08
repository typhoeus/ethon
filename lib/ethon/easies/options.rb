module Ethon
  module Easies
    module Options
      def self.included(base)
        base.extend ClassMethods
        base.const_set(:AVAILABLE_OPTIONS, [
          :httppost, :put, :httpget, :nobody, :upload, :customrequest,
          :cainfo, :capath, :connecttimeout,
          :followlocation, :httpauth, :infilesize, :interface,
          :maxredirs, :nosignal, :postfieldsize, :copypostfields, :proxy,
          :proxyauth, :proxytype, :timeout, :readdata, :sslcert, :ssl_verifypeer, :ssl_verifyhost,
          :sslcerttype, :sslkey, :sslkeytype, :sslversion,
          :url, :useragent, :userpwd, :verbose
        ])
        base.send(:attr_accessor, *Ethon::Easy::AVAILABLE_OPTIONS)
      end

      module ClassMethods
        def available_options
          Ethon::Easy::AVAILABLE_OPTIONS
        end

        def bool_options
          [
            :followlocation, :nosignal, :ssl_verifypeer, :ssl_verifyhost,
            :verbose, :httpget, :nobody, :upload
          ]
        end

        def enum_options
          { :httpauth => Curl::Auth }
        end

        def int_options
          [ :connecttimeout, :infilesize, :maxredirs, :postfieldsize, :timeout ]
        end
      end

      def set_options
        self.class.available_options.each do |option|
          value = value_for(option)
          next if value.nil?

          Curl.set_option(option, value, handle)
        end
      end

      def value_for(option)
        value = method(option).call
        return nil if value.nil?

        if self.class.bool_options.include?(option)
          value ? 1 : 0
        elsif self.class.enum_options.key?(option)
          self.class.enum_options[option][value]
        elsif self.class.int_options.include?(option)
          value.to_i
        else
          value
        end
      end
    end
  end
end
