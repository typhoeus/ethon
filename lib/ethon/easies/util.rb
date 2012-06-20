module Ethon
  module Easies # :nodoc:

    # This module contains small helpers.
    module Util

      # Return query pairs from hash.
      def build_query_pairs_from_hash(hash)
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
      def file_info(file)
        filename = File.basename(file.path)
        types = MIME::Types.type_for(filename)
        [
          filename,
          types.empty? ? 'application/octet-stream' : types[0].to_s,
          File.expand_path(file.path)
        ]
      end

      def self.escape_zero_byte(value)
        return value unless value.to_s.include?(0.chr)
        value.to_s.gsub(0.chr, '\\\0')
      end
    end
  end
end
