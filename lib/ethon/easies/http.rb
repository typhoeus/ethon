require 'ethon/easies/http/action'
require 'ethon/easies/http/actions/get'
require 'ethon/easies/http/actions/head'
require 'ethon/easies/http/actions/post'
require 'ethon/easies/http/actions/put'
require 'ethon/easies/http/actions/delete'

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
        Action.reset(self)
        Action.fabricate(action_name).new(url, options).setup(self)
      end
    end
  end
end
