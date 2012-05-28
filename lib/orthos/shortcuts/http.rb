require 'orthos/shortcuts/util'

module Orthos
  module Shortcuts
    module Http
      include Orthos::Shortcuts::Util

      def http_request(url, action, options = {})
        reset_http_request
        case action
        when :get
          self.http_get = true
          unless options[:params]
            self.url = url
          else
            query = build_query_string_from_hash(options[:params], true)
            self.url = "#{url}?#{query}"
          end
        when :post
          self.url = url
          unless options[:params]
            self.postfield_size = 0
            self.copy_postfields = ""
          else
            query = build_query_string_from_hash(options[:params], false)
            self.postfield_size = query.bytesize
            self.copy_postfields = query
          end
        when :put
          self.url = url
          self.upload = true
          self.infile_size = 0
        when :head
          self.nobody = true
          unless options[:params]
            self.url = url
          else
            query = build_query_string_from_hash(options[:params], true)
            self.url = "#{url}?#{query}"
          end
        end
      end

      def reset_http_request
        self.url = nil
        self.http_get = nil
        self.http_post = nil
        self.upload = nil
        self.nobody = nil
        self.custom_request = nil
        self.postfield_size = nil
        self.copy_postfields = nil
        self.infile_size = nil
      end
    end
  end
end

