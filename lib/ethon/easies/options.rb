module Ethon
  module Easies
    module Options
      def self.included(base)
        base.extend ClassMethods
        base.const_set(:AVAILABLE_OPTIONS, [
          :http_post, :put, :http_get, :nobody, :upload, :custom_request,
          :ca_info, :ca_path, :connect_timeout,
          :follow_location, :http_auth, :infile_size, :interface,
          :max_redirs, :no_signal, :postfield_size, :copy_postfields, :proxy,
          :proxy_auth, :proxy_type, :timeout, :read_data, :ssl_cert,
          :ssl_cert_type, :ssl_key, :ssl_key_type, :ssl_version,
          :url, :user_agent, :user_pwd, :verbose
        ])
        base.send(:attr_accessor, *Ethon::Easy::AVAILABLE_OPTIONS)
      end

      module ClassMethods
        def available_options
          Ethon::Easy::AVAILABLE_OPTIONS
        end

        def bool_options
          [
            :follow_location, :no_signal, :verify_peer, :verify_host,
            :verbose, :http_get, :nobody, :upload
          ]
        end

        def enum_options
          { :http_auth => Curl::Auth }
        end

        def int_options
          [ :connect_timeout, :infile_size, :max_redirs, :postfield_size, :timeout ]
        end
      end

      def set_options
        self.class.available_options.each do |option|
          value = value_for(option)
          next if value.nil?

          curl_option = option.to_s.tr('_', '').to_sym
          Curl.set_option(curl_option, value, handle)
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
