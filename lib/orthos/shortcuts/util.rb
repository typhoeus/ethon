require 'cgi'
require 'mime/types'
require 'tempfile'

module Orthos
  module Shortcuts
    module Util
      def build_query_pairs_from_hash(hash, escape_values=false)
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
              pairs << [key, file_info(v)]
            else
              v = CGI::escape(v.to_s) if escape
              pairs << [key, v]
            end
          end
        end
        recursive.call(hash, '')
        pairs
      end

      def file_info(file)
        filename = File.basename(file.path)
        types = MIME::Types.type_for(filename)
        [
          filename,
          types.empty? ? 'application/octet-stream' : types[0].to_s,
          File.expand_path(file.path)
        ]
      end
    end
  end
end
