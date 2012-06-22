require 'ethon/easies/util'

module Ethon
  module Easies

    # This class represents http request parameters.
    class Params
      include Ethon::Easies::Util
      attr_accessor :escape

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

      # Return the string representation of params.
      #
      # @example Return string representation.
      #   params.to_s
      #
      # @return [ String ] The string representation.
      def to_s
        query_pairs.map{|pair| pair.map{|e| escape ? CGI::escape(e.to_s) : e }.join("=")}.join('&')
      end

      # Return the query pairs.
      #
      # @example Return the query pairs.
      #   params.query_pairs
      #
      # @return [ Array ] The query pairs.
      def query_pairs
        @query_pairs ||= build_query_pairs(@params)
      end

      # Return wether there are elements in the params or not.
      #
      # @example Return if params is empty.
      #   params.empty?
      #
      # @return [ Boolean ] True if params is empty, else false.
      def empty?
        @params.empty?
      end
    end
  end
end
