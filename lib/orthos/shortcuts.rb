module Orthos
  module Shortcuts
    def action=(action)
      case action
      when :get
        self.http_get = true
      when :post
        self.http_post = true
      when :put
        self.upload = true
      when :head
        self.nobody = true
      else
        self.custom_request = action.to_s.upcase
      end
    end
  end
end

