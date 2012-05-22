require 'orthos/informations'
require 'orthos/callbacks'

module Orthos
  class Easy
    include Orthos::Informations
    include Orthos::Callbacks

    OPTIONS = [
      :action, :http_auth, :ca_info, :ca_path, :connect_timeout,
      :follow_location, :headers, :interface, :key_passwd,
      :max_redirs, :no_signal, :post_data, :proxy,
      :proxy_auth, :proxy_type, :request, :timeout, :ssl_cert,
      :ssl_cert_type, :ssl_key, :ssl_key_type, :ssl_version,
      :upload_data, :url, :user_agent, :user_pwd,
      :verify_peer, :verify_host
    ]

    BOOL_OPTIONS = [
      :follow_location, :no_signal, :verify_peer, :verify_host
    ]

    ENUM_OPTIONS = {
      :http_auth => :auth
   }

    attr_accessor *OPTIONS
    attr_reader :response_body, :response_header, :return_code

    class << self
      def finalizer(easy)
        proc {
          Curl.slist_free_all(easy.header_list) if easy.header_list
          Curl.easy_cleanup(easy.handle)
        }
      end
    end

    def initialize
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
    end

    def handle
      @handle ||= Curl.easy_init
    end

    def perform
      @return_code = Curl.easy_perform(handle)
    end

    def prepare
      OPTIONS.each do |option|
        value = value_for(option)
        next if value.nil?

        curl_option = option.to_s.tr('_', '').to_sym
        Curl.set_option(curl_option, value, handle)
      end
      Curl.set_option(:writefunction, body_write_callback, handle)
      Curl.set_option(:headerfunction, header_write_callback, handle)
      @response_body = ""
      @response_header = ""
    end

    def value_for(option)
      value = method(option).call
      return nil if value.nil?

      if BOOL_OPTIONS.include?(option)
        value = value ? 1 : 0
      elsif ENUM_OPTIONS.key?(option)
        value = Curl.const_get(ENUM_OPTIONS[option].to_s.camelize)[value]
      end
      value
    end
  end
end
