module Orthos
  module Stack
    def easy_handles
      @easy_handles ||= []
    end

    def add(easy)
      return nil if easy_handles.include?(easy)
      Curl.multi_add_handle(handle, easy.handle)
      easy_handles << easy
    end

    def delete(easy)
      if easy_handles.delete(easy)
        Curl.multi_remove_handle(handle, easy.handle)
      end
    end
  end
end
