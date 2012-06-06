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
        headers.each {|k, v| @header_list = Curl.slist_append(@header_list, "#{k}: #{v}") }
        Curl.set_option(:httpheader, @header_list, handle)
      end
    end
  end
end
