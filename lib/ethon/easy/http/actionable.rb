require 'ethon/easy/http/putable'
require 'ethon/easy/http/postable'

module Ethon
  class Easy
    module Http
      # This module represents a Http Action and is a factory
      # for more real actions like GET, HEAD, POST and PUT.
      module Actionable

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
          @options = options.dup
        end

        # Return the url.
        #
        # @example Return url.
        #   action.url
        #
        # @return [ String ] The url.
        def url
          @url
        end

        # Return the options hash.
        #
        # @example Return options.
        #   action.options
        #
        # @return [ Hash ] The options.
        def options
          @options
        end

        # Return the params.
        #
        # @example Return params.
        #   action.params
        #
        # @return [ Params ] The params.
        def params
          @params ||= Params.new(@easy, options.delete(:params))
        end

        # Return the form.
        #
        # @example Return form.
        #   action.form
        #
        # @return [ Form ] The form.
        def form
          @form ||= Form.new(@easy, options.delete(:body))
        end

        # Setup everything necessary for a proper request.
        #
        # @example setup.
        #   action.setup(easy)
        #
        # @param [ easy ] easy the easy to setup.
        def setup(easy)
          @easy = easy

          if params.empty?
            # This is called here to have the side effect of removing
            # the :params_encoding key from options, to avoid forwarding
            # it to Curl later. FIXME.
            params_encoding
            easy.url = url
          else
            set_params(easy)
          end
          set_form(easy) unless form.empty?
          easy.set_attributes(options)
        end

        # Setup request with params.
        #
        # @example Setup nothing.
        #   action.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_params(easy)
          params.escape = true
          params.params_encoding = params_encoding

          base_url, base_params = url.split("?")
          base_params += "&" if base_params
          easy.url = "#{base_url}?#{base_params}#{params.to_s}"
        end

        # Get the requested array encoding. By default it's
        # :typhoeus, but it can also be set to :rack.
        #
        # @example Get encoding from options
        #   action.params_encoding
        #
        def params_encoding
          @params_encoding ||= options.delete(:params_encoding) || :typhoeus
        end

        # Setup request with form.
        #
        # @example Setup nothing.
        #   action.set_form(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_form(easy)
        end
      end
    end
  end
end

