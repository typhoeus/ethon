module Ethon
  module Multies

    # This module provides the multi stack behaviour.
    module Stack

      # Return easy handles.
      #
      # @example Return easy handles.
      #   multi.easy_handles
      #
      # @return [ Array ] The easy handles.
      def easy_handles
        @easy_handles ||= []
      end

      # Add an easy to the stack.
      #
      # @example Add easy.
      #   multi.add(easy)
      #
      # @param [ Easy ] easy The easy to add.
      def add(easy)
        return nil if easy_handles.include?(easy)
        Curl.multi_add_handle(handle, easy.handle)
        easy_handles << easy
      end

      # Delete an easy from stack.
      #
      # @example Delete easy from stack.
      #
      # @param [ Easy ] easy The easy to delete.
      def delete(easy)
        if easy_handles.delete(easy)
          Curl.multi_remove_handle(handle, easy.handle)
        end
      end
    end
  end
end
