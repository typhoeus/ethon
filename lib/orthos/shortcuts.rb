module Orthos
  module Shortcuts
    def action=(action)
      reset_action
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

    def reset_action
      self.http_get = nil
      self.http_post = nil
      self.upload = nil
      self.nobody = nil
      self.custom_request = nil
    end
  end
end

