module Ethon
  module Easies
    module Http
      module Actions
        class Delete < Post
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
end

