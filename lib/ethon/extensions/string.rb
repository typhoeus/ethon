module Ethon
  module Extensions
    module String
      def byteslice(*args)
        self[*args]
      end
    end
  end
end

::String.__send__(:include, Ethon::Extensions::String)
