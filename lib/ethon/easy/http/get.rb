# frozen_string_literal: true
module Ethon
  class Easy
    module Http

      # This class knows everything about making GET requests.
      class Get
        include Ethon::Easy::Http::Actionable
        include Ethon::Easy::Http::Postable

        # Setup easy to make a GET request.
        #
        # @example Setup.
        #   get.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          if form.empty?
            easy.httpget = true
          else
            easy.customrequest = "GET"
          end
        end
      end
    end
  end
end
