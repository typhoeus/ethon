require 'orthos/easies/util'

module Orthos
  module Easies
    class Params
      include Orthos::Easies::Util
      attr_accessor :escape

      def initialize(params)
        @params = params || {}
      end

      def to_s
        query_pairs.map{|pair| pair.join("=")}.join('&')
      end

      def query_pairs
        @query_pairs ||= build_query_pairs_from_hash(@params, escape)
      end

      def empty?
        @params.empty?
      end
    end
  end
end
