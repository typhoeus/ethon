require 'orthos/informations'
require 'orthos/callbacks'

module Orthos
  class Easy
    include Orthos::Informations
    include Orthos::Callbacks

    OPTIONS = [
      :post, :put, :http_get, :nobody,
      :ca_info, :ca_path, :connect_timeout,
      :follow_location, :http_auth, :interface,
      :max_redirs, :no_signal, :postfield_size, :copy_postfields, :proxy,
      :proxy_auth, :proxy_type, :timeout, :ssl_cert,
      :ssl_cert_type, :ssl_key, :ssl_key_type, :ssl_version,
      :url, :user_agent, :user_pwd, :verbose
    ]

    BOOL_OPTIONS = [
      :follow_location, :no_signal, :verify_peer, :verify_host,
      :verbose, :http_get, :http_post, :nobody, :upload
    ]

    INT_OPTIONS = [
      :connect_timeout, :max_redirs, :postfield_size, :timeout
    ]

    ENUM_OPTIONS = {
      :http_auth => Curl::Auth
   }

    attr_accessor *OPTIONS
    attr_reader :response_body, :response_header, :return_code, :action
    attr_writer :headers

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

    def action=(action)
      case action
      when :get
        http_get = true
      when :post
        http_post = true
      when :put
        upload = true
      when :head
        nobody = true
      else
        custom_request = action.to_s.upcase
      end
    end

    def headers
      @headers ||= {}
    end

    def handle
      @handle ||= Curl.easy_init
    end

    def perform
      @return_code = Curl.easy_perform(handle)
    end

    def prepare
      set_options
      set_headers
      set_callbacks
    end

    def set_options
      OPTIONS.each do |option|
        value = value_for(option)
        next if value.nil?

        curl_option = option.to_s.tr('_', '').to_sym
        Curl.set_option(curl_option, value, handle)
      end
    end

    def set_headers
      @header_list = nil
      headers.each {|k, v| @header_list = Curl.slist_append(@header_list, "#{k}: #{v}") }
      Curl.set_option(:httpheader, @header_list, handle)
    end

    def value_for(option)
      value = method(option).call
      return nil if value.nil?

      if BOOL_OPTIONS.include?(option)
        value ? 1 : 0
      elsif ENUM_OPTIONS.key?(option)
        ENUM_OPTIONS[option][value]
      elsif INT_OPTIONS.include?(option)
        value.to_i
      else
        value
      end
    end
  end
end
