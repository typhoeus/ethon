module Ethon
  module Easies
    module Http
      module Actions
        class Post < Action
          def setup(easy)
            if params.empty? && form.empty?
              easy.url = url
              easy.postfield_size = 0
              easy.copy_postfields = ""
            end
            if !params.empty?
              params.escape = true
              easy.url = "#{url}?#{params.to_s}"
              easy.postfield_size = 0
              easy.copy_postfields = ""
            end
            if !form.empty?
              easy.url = url
              form.escape = false
              form.materialize
              easy.http_post = form.first.read_pointer
            end
          end
        end
      end
    end
  end
end
