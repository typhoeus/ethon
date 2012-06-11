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

  # This is the class representing the libcurl easy interface
  # See http://curl.haxx.se/libcurl/c/libcurl-easy.html for more informations.
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

      # Free libcurl representation from an easy handle.
      #
      # @example Free easy handle.
      #   Easy.finalizer(easy)
      #
      # @param [ Easy ] easy The easy to free.
      def finalizer(easy)
        proc {
          Curl.slist_free_all(easy.header_list) if easy.header_list
          Curl.easy_cleanup(easy.handle)
        }
      end
    end

    # Initialize a new Easy.
    # It initializes curl, if not already done and applies the provided options.
    #
    # @example Create a new Easy.
    #   Easy.new(:url => "www.google.de")
    #
    # @param [ Hash ] options The options to set.
    #
    # @return [ Easy ] A new Easy.
    def initialize(options = {})
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))

      options.each_pair do |key, value|
        method("#{key}=").call(value)
      end
    end

    # Returns a  pointer to the curl easy handle.
    #
    # @example Return the handle.
    #   easy.handle
    #
    # @return [ FFI::Pointer ] A pointer to the curl easy handle.
    def handle
      @handle ||= Curl.easy_init
    end
  end
end
