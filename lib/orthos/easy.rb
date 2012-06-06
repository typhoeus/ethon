require 'orthos/easies/informations'
require 'orthos/easies/callbacks'
require 'orthos/easies/options'
require 'orthos/easies/header'
require 'orthos/easies/util'
require 'orthos/easies/params'
require 'orthos/easies/form'
require 'orthos/easies/http'
require 'orthos/easies/operations'

module Orthos
  class Easy
    include Orthos::Easies::Informations
    include Orthos::Easies::Callbacks
    include Orthos::Easies::Options
    include Orthos::Easies::Header
    include Orthos::Easies::Http
    include Orthos::Easies::Operations

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
