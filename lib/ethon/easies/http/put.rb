module Ethon
  module Easies
    module Http

      # This class knows everything about making PUT requests.
      class Put
        include Ethon::Easies::Http::Actionable
        include Ethon::Easies::Http::Putable

        def set_customs(easy)
          if form.empty?
            easy.upload = true
            easy.infilesize = 0
          end
        end
      end
    end
  end
end
