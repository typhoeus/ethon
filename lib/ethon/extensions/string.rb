module Ethon

  # This module contains all core extensions ethon
  # needs.
  module Extensions
    module String # :nodoc:

      # Return part of the string.
      #
      # @return [ String ] Part of the string.
      def byteslice(*args)
        self[*args]
      end
    end
  end
end

::String.__send__(:include, Ethon::Extensions::String)
