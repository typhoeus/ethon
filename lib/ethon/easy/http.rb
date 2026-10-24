# frozen_string_literal: true
require 'ethon/easy/http/actionable'
require 'ethon/easy/http/post'
require 'ethon/easy/http/get'
require 'ethon/easy/http/head'
require 'ethon/easy/http/put'
require 'ethon/easy/http/delete'
require 'ethon/easy/http/patch'
require 'ethon/easy/http/options'
require 'ethon/easy/http/custom'

module Ethon
  class Easy

    # This module contains logic about making valid HTTP requests.
    module Http

      # Built-in request actions. Custom verbs must not resolve to helper
      # modules or classes that happen to live in this namespace.
      ACTION_CLASSES = {
        "get" => Get,
        "head" => Head,
        "post" => Post,
        "put" => Put,
        "delete" => Delete,
        "patch" => Patch,
        "options" => Options
      }.freeze

      # Set specified options in order to make a HTTP request.
      # Look at {Ethon::Easy::Options Options} to see what you can
      # provide in the options hash.
      #
      # @example Set options for HTTP request.
      #   easy.http_request("www.google.com", :get, {})
      #
      # @param [ String ] url The url.
      # @param [ String ] action_name The HTTP action name.
      # @param [ Hash ] options The options hash.
      #
      # @option options :params [ Hash ] Params hash which
      #   is attached to the url.
      # @option options :body [ Hash ] Body hash which
      #   becomes the request body. It is a PUT body for
      #   PUT requests and a POST for everything else.
      # @option options :headers [ Hash ] Request headers.
      #
      # @return [ void ]
      #
      # @see Ethon::Easy::Options
      def http_request(url, action_name, options = {})
        fabricate(url, action_name, options).setup(self)
      end

      private

      # Return the corresponding action class.
      #
      # @example Return the action.
      #   Action.fabricate(:get)
      #   Action.fabricate(:smash)
      #
      # @param [ String ] url The url.
      # @param [ String ] action_name The HTTP action name.
      # @param [ Hash ] options The option hash.
      #
      # @return [ Easy::Ethon::Actionable ] The request instance.
      def fabricate(url, action_name, options)
        action_class = ACTION_CLASSES[action_name.to_s.downcase]

        if action_class
          action_class.new(url, options)
        else
          Ethon::Easy::Http::Custom.new(action_name.to_s.upcase, url, options)
        end
      end

    end
  end
end
