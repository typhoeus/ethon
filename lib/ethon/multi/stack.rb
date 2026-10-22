# frozen_string_literal: true
module Ethon
  class Multi

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
      #
      # @raise [ Ethon::Errors::MultiAdd ] If adding an easy failed.
      def add(easy)
        return nil if easy_handles.include?(easy)

        easy.clear_callback_error
        easy_handles << easy
        code = Curl.multi_add_handle(handle, easy.handle)
        unless code == :ok
          easy_handles.delete(easy)
          raise Errors::MultiAdd.new(code, easy)
        end

        easy_handles
      end

      # Delete an easy from stack.
      #
      # @example Delete easy from stack.
      #
      # @param [ Easy ] easy The easy to delete.
      #
      # @raise [ Ethon::Errors::MultiRemove ] If removing an easy failed.
      def delete(easy)
        if (index = easy_handles.index(easy))
          easy_handles.delete_at(index)
          code = Curl.multi_remove_handle(handle, easy.handle)
          unless code == :ok
            easy_handles.insert(index, easy)
            raise Errors::MultiRemove.new(code, easy)
          end
        end
      end
    end
  end
end
