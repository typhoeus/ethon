module Ethon
  module Easies
    module Http

      # Base class for all the requests
      class BaseRequest
        include Ethon::Easies::Http::Actionable

        # Custom Setup. Should be overriden in derived class.
        #
        # @param [ Easy ] easy The easy to setup.
        def set_customs(easy)
          raise "This method should be overriden in derived class"
        end
      end
    end
  end
end
