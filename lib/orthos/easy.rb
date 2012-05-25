require 'orthos/informations'
require 'orthos/callbacks'
require 'orthos/header'
require 'orthos/options'
require 'orthos/shortcuts/http'
require 'orthos/operations/easy'

module Orthos
  class Easy
    include Orthos::Informations
    include Orthos::Callbacks
    include Orthos::Options
    include Orthos::Header
    include Orthos::Shortcuts::Http
    include Orthos::Operations::Easy

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

    def initialize
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
    end

    def handle
      @handle ||= Curl.easy_init
    end
  end
end
