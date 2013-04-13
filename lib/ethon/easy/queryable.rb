module Ethon
  class Easy

    # This module contains logic about building
    # query parameters for url or form.
    module Queryable

      # :nodoc:
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
        @to_s ||= query_pairs.map{ |pair|
          return pair if pair.is_a?(String)

          if escape && @easy
            pair.map{ |e| @easy.escape(e.to_s) }.join("=")
          else
            pair.join("=")
          end
        }.join('&')
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

      # Return query pairs build from a hash.
      #
      # @example Build query pairs.
      #   action.build_query_pairs({a: 1, b: 2})
      #   #=> [[:a, 1], [:b, 2]]
      #
      # @param [ Hash ] hash The hash to go through.
      #
      # @return [ Array ] The array of query pairs.
      def build_query_pairs(hash)
        return [hash] if hash.is_a?(String)

        pairs = []
        recursively_generate_pairs(hash, nil, pairs)
        pairs
      end

      # Return file info for a file.
      #
      # @example Return file info.
      #   action.file_info(File.open('fubar', 'r'))
      #
      # @param [ File ] file The file to handle.
      #
      # @return [ Array ] Array of informations.
      def file_info(file)
        filename = File.basename(file.path)
        types = MIME::Types.type_for(filename)
        [
          filename,
          types.empty? ? 'application/octet-stream' : types[0].to_s,
          File.expand_path(file.path)
        ]
      end

      private

      def recursively_generate_pairs(h, prefix, pairs)
        case h
        when Hash
          h.each_pair do |k,v|
            key = prefix.nil? ? k : "#{prefix}[#{k}]"
            pairs_for(v, key, pairs)
          end
        when Array
          h.each_with_index do |v, i|
            key = "#{prefix}[#{i}]"
            pairs_for(v, key, pairs)
          end
        end
      end

      def pairs_for(v, key, pairs)
        case v
        when Hash
          recursively_generate_pairs(v, key, pairs)
        when Array
          recursively_generate_pairs(v, key, pairs)
        when File, Tempfile
          pairs << [Util.escape_zero_byte(key), file_info(v)]
        else
          pairs << [Util.escape_zero_byte(key), Util.escape_zero_byte(v)]
        end
      end
    end
  end
end
