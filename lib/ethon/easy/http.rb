require 'ethon/easy/http/actionable'
require 'ethon/easy/http/post'
require 'ethon/easy/http/get'
require 'ethon/easy/http/head'
require 'ethon/easy/http/put'
require 'ethon/easy/http/delete'
require 'ethon/easy/http/patch'
require 'ethon/easy/http/options'

module Ethon
  class Easy

    # This module contains logic about making valid http requests.
    module Http

      # Set specified options in order to make a http request.
      # Look into {Ethon::Easy::Options Options} to see what you can
      # provide in the options hash.
      #
      # @example Set options for http request.
      #   easy.http_request("www.google.com", :get, {})
      #
      # @param [ String ] url The url.
      # @param [ String ] action_name The http action name.
      # @param [ Hash ] options The options hash.
      #
      # @option options :params [ Hash ] Params hash which
      #   is attached to the url.
      # @option options :body [ Hash ] Body hash which
      #   becomes the request body. It is a PUT body for
      #   PUT requests and a POST from for everything else.
      # @option options :headers [ Hash ] Request headers.
      #
      # @return [ void ]
      #
      # @see Ethon::Easy::Options
      def http_request(url, action_name, options = {})
        fabricate(action_name).new(url, options).setup(self)
      end

      private

      # Return the corresponding action class.
      #
      # @example Return the action.
      #   Action.fabricate(:get)
      #
      # @param [ String ] action_name The action name.
      #
      # @return [ Class ] The action class.
      def fabricate(action_name)
        Ethon::Easy::Http.const_get(action_name.to_s.capitalize)
      end
    end
  end
end
