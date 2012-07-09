module Ethon
  module Easies
    module Http

      # This class knows everything about making DELETE requests.
      class Delete < Request
        include Ethon::Easies::Http::Postable

        # Setup easy to make a DELETE request.
        #
        # @example Setup customrequest.
        #   delete.setup(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          easy.customrequest = "DELETE"
        end
      end
    end
  end
end

