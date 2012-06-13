module Ethon
  module Easies
    module Http
      # This class represents a Http Action and is a factory
      # for more real actions like GET, HEAD, POST and PUT.
      class Action
        attr_reader :url, :params, :form

        class << self

          # Return the corresponding action class.
          #
          # @example Return the action.
          #   Action.fabricate(:get)
          #
          # @param [ String ] action_name The action name.
          #
          # @return [ Class ] The action class.
          def fabricate(action_name)
            eval("Actions::#{action_name.capitalize}")
          end

          # Resets every attribute possibly set by an action.
          #
          # @example Reset attributes,
          #   Action.reset(easy)
          #
          # @param [ Easy ] easy The easy to reset.
          def reset(easy)
            easy.url = nil
            easy.httpget = nil
            easy.httppost = nil
            easy.upload = nil
            easy.nobody = nil
            easy.customrequest = nil
            easy.postfieldsize = nil
            easy.copypostfields = nil
            easy.infilesize = nil
          end
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
          @params = Params.new(options[:params])
          @form = Form.new(options[:body])
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
        end

        # Setup request as if there were no params and form.
        #
        # @example Setup nothing.
        #   action.set_nothing(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_nothing(easy)
        end

        # Setup request as with params.
        #
        # @example Setup nothing.
        #   action.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_params(easy)
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

