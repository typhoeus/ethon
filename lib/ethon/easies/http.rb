require 'ethon/easies/http/actionable'
require 'ethon/easies/http/post'
require 'ethon/easies/http/get'
require 'ethon/easies/http/head'
require 'ethon/easies/http/put'
require 'ethon/easies/http/delete'
require 'ethon/easies/http/patch'
require 'ethon/easies/http/options'

module Ethon
  module Easies

    # This module contains logic about making valid http requests.
    module Http

      # Set specified options in order to make a http request.
      #
      # @example Set options for http request.
      #   easy.http_request("www.google.com", :get, {})
      #
      # @param [ String ] url The url.
      # @param [ String ] action_name The http action name.
      # @param [ Hash ] options The options hash.
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
        eval("#{action_name.capitalize}")
      end
    end
  end
end
