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

        # Another Multi may still own the handle natively. Reject before
        # resetting its transfer state or touching its response stream.
        if easy.instance_variable_get(:@multi)
          raise Errors::EthonError, "Easy is still attached to a Multi; remove it first"
        end

        # Resolve the multi handle before changing the easy so a cleaned up or
        # forked Multi cannot reset the easy or open its response file.
        begin
          multi_handle = handle
          easy_handle = easy.handle
          easy.prepare_response_body_io
          easy.reset_transfer_state
          easy.clear_callback_error
          easy_handles << easy
          code = Curl.multi_add_handle(multi_handle, easy_handle)
          raise Errors::MultiAdd.new(code, easy) unless code == :ok
        rescue Exception
          easy_handles.delete(easy)
          # A failed add must not leave a response file open until GC.
          easy.finish_response_body_io
          raise
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
          easy.finish_response_body_io
        end
      end
    end
  end
end
