module Ethon
  module Easies
    module Http
      class Action
        attr_reader :url, :params, :form

        class << self
          def fabricate(action_name)
            eval("Actions::#{action_name.capitalize}")
          end

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

        def initialize(url, options)
          @url = url
          @params = Params.new(options[:params])
          @form = Form.new(options[:body])
        end
      end
    end
  end
end

