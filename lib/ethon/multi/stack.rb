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

        easy.prepare_response_body_io
        easy.reset_transfer_state
        easy.clear_callback_error
        easy_handle = easy.handle
        easy_handles << easy
        begin
          code = Curl.multi_add_handle(handle, easy_handle)
        rescue Exception
          easy_handles.delete(easy)
          raise
        end
        unless code == :ok
          easy_handles.delete(easy)
          raise Errors::MultiAdd.new(code, easy)
        end

        # Cleanup must not free an easy that is still attached to this multi.
        easy.instance_variable_set(:@multi, self)
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
          begin
            code = Curl.multi_remove_handle(handle, easy.handle)
          rescue Exception
            easy_handles.insert(index, easy)
            raise
          end
          unless code == :ok
            easy_handles.insert(index, easy)
            raise Errors::MultiRemove.new(code, easy)
          end

          easy.instance_variable_set(:@multi, nil) if easy.instance_variable_get(:@multi).equal?(self)
        end
      end
    end
  end
end
