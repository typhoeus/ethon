module Ethon
  module Easies
    module Queryable

      def self.included(base)
        base.send(:attr_accessor, :escape)
      end

      # Return wether there are elements in the form or not.
      #
      # @example Return if form is empty.
      #   form.empty?
      #
      # @return [ Boolean ] True if form is empty, else false.
      def empty?
        @params.empty?
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
    end
  end
end
