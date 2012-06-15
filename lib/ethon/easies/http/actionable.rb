require 'ethon/easies/http/putable'
require 'ethon/easies/http/postable'

module Ethon
  module Easies
    module Http
      # This module represents a Http Action and is a factory
      # for more real actions like GET, HEAD, POST and PUT.
      module Actionable

        def url
          @url
        end

        def options
          @options
        end

        def params
          @params ||= Params.new(options[:params])
        end

        def form
          @form ||= Form.new(options[:body])
        end

        # Create a new action.
        #
        # @example Create a new action.
        #   Action.new("www.example.com", {})
        #
        # @param [ String ] url The url.
        # @param [ Hash ] options The options.
        #
        # @return [ Action ] A new action.
        def initialize(url, options)
          @url = url
          @options = options
        end

        # Setup everything what is necessary for a proper
        # request.
        #
        # @example setup.
        #   action.setup(easy)
        #
        # @param [ easy ] easy the easy to setup.
        def setup(easy)
          set_nothing(easy) if params.empty? && form.empty?
          set_params(easy) unless params.empty?
          set_form(easy) unless form.empty?
          set_customs(easy)
          easy.set_attributes(options)
        end

        # Setup request as if there were no params and form.
        #
        # @example Setup nothing.
        #   action.set_nothing(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_nothing(easy)
          easy.url = url
        end

        # Setup request as with params.
        #
        # @example Setup nothing.
        #   action.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_params(easy)
          params.escape = true
          easy.url = "#{url}?#{params.to_s}"
        end

        # Setup request as with form.
        #
        # @example Setup nothing.
        #   action.set_form(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_form(easy)
        end

        # Setup custom things eg. override the i
        # action for delete.
        #
        # @example Setup custom things.
        #   action.set_customs(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_customs(easy)
        end
      end
    end
  end
end

