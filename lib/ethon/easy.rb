require 'ethon/easies/informations'
require 'ethon/easies/callbacks'
require 'ethon/easies/options'
require 'ethon/easies/header'
require 'ethon/easies/util'
require 'ethon/easies/params'
require 'ethon/easies/form'
require 'ethon/easies/http'
require 'ethon/easies/operations'
require 'ethon/easies/response_callbacks'

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
    include Ethon::Easies::ResponseCallbacks

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
    # @option options :cainfo [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCAINFO.
    # @option options :capath [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCAPATH.
    # @option options :connecttimeout [Integer] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCONNECTTIMEOUT.
    # @option options :copypostfields [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCOPYPOSTFIELDS.
    # @option options :customrequest [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCUSTOMREQUEST.
    # @option options :followlocation [Boolean] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTFOLLOWLOCATION.
    # @option options :httpauth [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTHTTPAUTH.
    # @option options :httpget [Boolean] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTHTTPGET.
    # @option options :httppost [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTHTTPPOST.
    # @option options :infilesize [Integer] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTINFILESIZE.
    # @option options :interface [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTINTERFACE.
    # @option options :maxredirs [Integer] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTMAXREDIRS.
    # @option options :nobody [Boolean] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTNOBODY.
    # @option options :nosignal [Boolean] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTNOSIGNAL.
    # @option options :postfieldsize [Integer] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTPOSTFIELDSIZE.
    # @option options :proxy [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTPROXY.
    # @option options :proxyauth [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTPROXYAUTH.
    # @option options :proxytype [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTPROXYTYPE.
    # @option options :put [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTPUT.
    # @option options :readdata [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTREADDATA.
    # @option options :readfunction [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTREADFUNCTION.
    # @option options :ssl_verifyhost [Integer] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTSSLVERIFYHOST.
    # @option options :ssl_verifypeer [Boolean] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTSSLVERIFYPEER.
    # @option options :sslcert [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTSSLCERT.
    # @option options :sslcerttype [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTSSLCERTTYPE.
    # @option options :sslkey [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTSSLKEY.
    # @option options :sslkeytype [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTSSLKEYTYPE.
    # @option options :sslversion [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTSSLVERSION.
    # @option options :timeout [Integer] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTTIMEOUT.
    # @option options :upload [Boolean] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTUPLOAD.
    # @option options :url [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTURL.
    # @option options :useragent [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTUSERAGENT.
    # @option options :userpwd [String] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTUSERPWD.
    # @option options :verbose [Boolean] See
    #  http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTVERBOSE.
    #
    # @return [ Easy ] A new Easy.
    def initialize(options = {})
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      set_attributes(options)
    end

    # Set given options.
    #
    # @example Set options.
    #   easy.set_attributes(options)
    #
    # @param [ Hash ] options The options.
    def set_attributes(options)
      options.each_pair do |key, value|
        method("#{key}=").call(value) if respond_to?("#{key}=")
      end
    end

    # Reset easy. This means resetting all options and instance variables.
    # Also the easy handle is resetted.
    #
    # @example Reset.
    #   easy.reset
    def reset
      (instance_variables - [:@handle, :@header_list]).each do |ivar|
        instance_variable_set(ivar, nil)
      end
      Curl.easy_reset(handle)
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

    def to_hash
      hash = {}
      hash[:return_code] = return_code
      hash[:response_header] = response_header
      hash[:response_body] = response_body
      Easies::Informations::AVAILABLE_INFORMATIONS.keys.each do |info|
        hash[info] = method(info).call
      end
      hash
    end
  end
end
