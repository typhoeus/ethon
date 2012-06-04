require 'orthos/shortcuts/util'

module Orthos
  module Shortcuts
    module Http
      def http_request(url, action, options = {})
        reset_http_request
        params = Params.new(options[:params])
        form = Form.new(options[:body])
        case action
        when :get
          self.http_get = true
          if params.empty?
            self.url = url
          else
            params.escape = true
            self.url = "#{url}?#{params.to_s}"
          end
        when :post
          if params.empty? && form.empty?
            self.url = url
            self.postfield_size = 0
            self.copy_postfields = ""
          end
          if !params.empty?
            params.escape = true
            self.url = "#{url}?#{params.to_s}"
            self.postfield_size = 0
            self.copy_postfields = ""
          end
          if !form.empty?
            self.url = url
            form.escape = false
            form.materialize
            self.http_post = form.first.read_pointer
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

