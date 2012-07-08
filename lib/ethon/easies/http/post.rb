module Ethon
  module Easies
    module Http
      # This class knows everything about making POST requests.
      class Post < Request
        include Ethon::Easies::Http::Postable

        # Setup easy to make a POST request.
        #
        # @example Setup.
        #   post.setup(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          if form.empty?
            easy.postfieldsize = 0
            easy.copypostfields = ""
          end
        end
      end
    end
  end
end
