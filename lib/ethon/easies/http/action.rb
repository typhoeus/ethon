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
            easy.http_get = nil
            easy.http_post = nil
            easy.upload = nil
            easy.nobody = nil
            easy.custom_request = nil
            easy.postfield_size = nil
            easy.copy_postfields = nil
            easy.infile_size = nil
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

