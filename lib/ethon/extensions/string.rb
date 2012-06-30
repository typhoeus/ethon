module Ethon

  # This module contains all core extensions ethon
  # needs.
  module Extensions
    module String # :nodoc:

      unless ''.respond_to?(:byteslice)
        # Return part of the string.
        #
        # @return [ String ] Part of the string.
        def byteslice(*args)
          self[*args]
        end
      end

      # Convert string to underscore. Taken from
      # activesupport, renamed in order to no collide
      # with it.
      #
      # @example Underscore.
      #   "ClassName".underscr
      #   #=> "class_name"
      #
      # @return [ String ] Underscore string.
      def underscr
        word = self.dup
        word.gsub!('::', '_')
        word.gsub!(/(?:([A-Za-z\d])|^)(#{/(?=a)b/})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end
    end
  end
end

::String.__send__(:include, Ethon::Extensions::String)
