require 'ethon/easies/util'
require 'ethon/easies/queryable'

module Ethon
  module Easies

    # This class represents http request parameters.
    class Params
      include Ethon::Easies::Util
      include Ethon::Easies::Queryable

      # Create a new Params.
      #
      # @example Create a new Params.
      #   Params.new({})
      #
      # @param [ Hash ] params The params to use.
      #
      # @return [ Params ] A new Params.
      def initialize(params)
        @params = params || {}
      end
    end
  end
end
