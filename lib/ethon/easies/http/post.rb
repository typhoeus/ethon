module Ethon
  module Easies
    module Http
      # This class knows everything about making POST requests.
      class Post < BaseRequest
        include Ethon::Easies::Http::Postable

        def set_customs(easy)
          if form.empty?
            easy.postfieldsize = 0
            easy.copypostfields = ""
          end
        end
      end
    end
  end
end
