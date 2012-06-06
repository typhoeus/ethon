require 'ethon/easies/informations'
require 'ethon/easies/callbacks'
require 'ethon/easies/options'
require 'ethon/easies/header'
require 'ethon/easies/util'
require 'ethon/easies/params'
require 'ethon/easies/form'
require 'ethon/easies/http'
require 'ethon/easies/operations'

module Ethon
  class Easy
    include Ethon::Easies::Informations
    include Ethon::Easies::Callbacks
    include Ethon::Easies::Options
    include Ethon::Easies::Header
    include Ethon::Easies::Http
    include Ethon::Easies::Operations

    attr_reader :response_body, :response_header
    attr_accessor :return_code

    class << self
      def finalizer(easy)
        proc {
          Curl.slist_free_all(easy.header_list) if easy.header_list
          Curl.easy_cleanup(easy.handle)
        }
      end
    end

    def initialize(options = {})
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))

      options.each_pair do |key, value|
        method("#{key}=").call(value)
      end
    end

    def handle
      @handle ||= Curl.easy_init
    end
  end
end
