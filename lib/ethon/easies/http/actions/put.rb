module Ethon
  module Easies
    module Http
      module Actions
        class Put < Action
          def setup(easy)
            easy.url = url
            easy.upload = true
            easy.infile_size = 0
          end
        end
      end
    end
  end
end
