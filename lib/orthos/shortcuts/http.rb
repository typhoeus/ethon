require 'orthos/shortcuts/util'

module Orthos
  module Shortcuts
    module Http
      include Orthos::Shortcuts::Util

      def http_request(url, action, options = {})
        reset_http_request
        params = Params.new(options[:params])
        body = Form.new(options[:body])
        case action
        when :get
          self.http_get = true
          unless options[:params]
            self.url = url
          else
            params.escape = true
            self.url = "#{url}?#{params.to_s}"
          end
        when :post
          self.url = url
          if params.empty?
            self.postfield_size = 0
            self.copy_postfields = ""
          else
            params.escape = false
            self.postfield_size = params.to_s.bytesize
            self.copy_postfields = params.to_s
          end
        when :put
          self.url = url
          self.upload = true
          self.infile_size = 0
        when :head
          self.nobody = true
          if params.empty?
            self.url = url
          else
            params.escape = true
            self.url = "#{url}?#{params.to_s}"
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

