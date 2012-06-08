require 'ethon/easies/http/action'
require 'ethon/easies/http/actions/get'
require 'ethon/easies/http/actions/head'
require 'ethon/easies/http/actions/post'
require 'ethon/easies/http/actions/put'

module Ethon
  module Easies
    module Http
      def http_request(url, action_name, options = {})
        Action.reset(self)
        Action.fabricate(action_name).new(url, options).setup(self)
      end
    end
  end
end
