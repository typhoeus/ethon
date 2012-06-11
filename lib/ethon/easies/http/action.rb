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
      end
    end
  end
end

