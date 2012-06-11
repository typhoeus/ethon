module Ethon
  module Easies
    module Header
      def headers
        @headers ||= {}
      end

      def headers=(headers)
        @headers = headers
      end

      def set_headers
        @header_list = nil
        headers.each {|k, v| @header_list = Curl.slist_append(@header_list, compose_header(k,v)) }
        Curl.set_option(:httpheader, @header_list, handle)
      end

      def compose_header(key, value)
        "#{key}:#{value.gsub(0.chr, '\\\0')}"
      end
    end
  end
end
