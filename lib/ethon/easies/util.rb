module Ethon
  module Easies # :nodoc:

    # This module contains small helpers.
    module Util

      # Return query pairs build from a hash.
      #
      # @example Build query pairs.
      #   action.build_query_pairs({:a => 1, :b => 2})
      #   #=> [[:a, 1], [:b, 2]]
      #
      # @param [ Hash ] hash The hash to go through.
      #
      # @return [ Array ] The array of query pairs.
      def build_query_pairs(hash)
        pairs = []
        recursive = Proc.new do |h, prefix|
          h.each_pair do |k,v|
            key = prefix == '' ? k : "#{prefix}[#{k}]"
            case v
            when Hash
              recursive.call(v, key)
            when Array
              v.each { |x| pairs << [key, x]  }
            when File, Tempfile
              pairs << [Util.escape_zero_byte(key), file_info(v)]
            else
              pairs << [Util.escape_zero_byte(key), Util.escape_zero_byte(v)]
            end
          end
        end
        recursive.call(hash, '')
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

      # Escapes zero bytes in strings.
      #
      # @example Escape zero bytes.
      #   Util.escape_zero_byte("1\0")
      #   #=> "1\\0"
      #
      # @param [ Object ] value The value to escape.
      #
      # @return [ String, Object ] Escaped String if
      #   zero byte found, original object if not.
      def self.escape_zero_byte(value)
        return value unless value.to_s.include?(0.chr)
        value.to_s.gsub(0.chr, '\\\0')
      end
    end
  end
end
