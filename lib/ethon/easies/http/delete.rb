module Ethon
  module Easies
    module Http

      # This class knows everything about making DELETE requests.
      class Delete
        include Ethon::Easies::Http::Actionable
        include Ethon::Easies::Http::Postable

        # Setup customrequest in order to make a delete.
        #
        # @example Setup customrequest.
        #   delete.setup(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def set_customs(easy)
          easy.customrequest = "DELETE"
        end
      end
    end
  end
end

