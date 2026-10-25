# frozen_string_literal: true
module Ethon
  class Easy

    # This module contains logic about building
    # query parameters for url or form.
    module Queryable
      # Marker for the [filename, content type, path] triple produced for a
      # file upload. It stays an Array for compatibility, but lets the form
      # builders tell a file from an array value that was left untransformed
      # by params_encoding :none.
      class FileInfo < Array
      end

      attr_reader :escape, :params_encoding

      def escape=(value)
        @to_s = nil
        @escape = value
      end

      def params_encoding=(value)
        @query_pairs = nil
        @to_s = nil
        @params_encoding = value
      end

      # Loads mime-types on first use rather than when ethon is required:
      # its registry costs megabytes in every process, while only file
      # uploads need it. Concurrent first calls are safe, `require` is.
      #
      # @return [ Boolean ] True if mime-types could be loaded.
      def self.mime_types_available?
        return @mime_types_available unless @mime_types_available.nil?

        @mime_types_available = begin
          require 'mime/types/columnar'
          true
        rescue LoadError
          begin
            require 'mime/types'
            true
          rescue LoadError
            false
          end
        end
      end

      # Return wether there are elements in params or not.
      #
      # @example Return if params is empty.
      #   form.empty?
      #
      # @return [ Boolean ] True if params is empty, else false.
      def empty?
        # Build the pairs instead of asking @params directly: params may be a
        # String or a scalar, and only the pairs describe what is sent.
        query_pairs.empty?
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
        if hash.is_a?(String)
          # An empty string describes no pairs. Treating it as one would make
          # #empty? false and leave a stray "?" or "&" in the url.
          return hash.empty? ? [] : [hash]
        end

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
        FileInfo.new([
          filename,
          mime_type(filename),
          File.expand_path(file.path)
        ])
      end

      private

      def mime_type(filename)
        if Queryable.mime_types_available? && defined?(MIME) && t = MIME::Types.type_for(filename).first
          t.to_s
        else
          'application/octet-stream'
        end
      end

      def recursively_generate_pairs(h, prefix, pairs)
        case h
        when Hash
          encode_hash_pairs(h, prefix, pairs)
        when Array
          if params_encoding == :rack
            encode_rack_array_pairs(h, prefix, pairs)
          elsif params_encoding == :multi
            encode_multi_array_pairs(h, prefix, pairs)
          elsif params_encoding == :none
            pairs << [prefix, h]
          else
            encode_indexed_array_pairs(h, prefix, pairs)
          end
        end
      end

      def encode_hash_pairs(h, prefix, pairs)
        h.each_pair do |k,v|
          key = prefix.nil? ? k : "#{prefix}[#{k}]"
          pairs_for(v, key, pairs)
        end
      end

      def encode_indexed_array_pairs(h, prefix, pairs)
        h.each_with_index do |v, i|
          key = "#{prefix}[#{i}]"
          pairs_for(v, key, pairs)
        end
      end

      def encode_rack_array_pairs(h, prefix, pairs)
        h.each do |v|
          key = "#{prefix}[]"
          pairs_for(v, key, pairs)
        end
      end

      def encode_multi_array_pairs(h, prefix, pairs)
        h.each do |v|
          pairs_for(v, prefix, pairs)
        end
      end

      def pairs_for(v, key, pairs)
        case v
        when Hash, Array
          recursively_generate_pairs(v, key, pairs)
        when File, Tempfile
          pairs << [key, file_info(v)]
        else
          pairs << [key, v]
        end
      end
    end
  end
end
