module Orthos
  module Shortcuts
    def action=(action)
      case action
      when :get
        http_get = true
      when :post
        http_post = true
      when :put
        upload = true
      when :head
        nobody = true
      else
        custom_request = action.to_s.upcase
      end
    end
  end
end

