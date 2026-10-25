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
      # A failed add leaves the Easy untouched: its previous response and any
      # streamed response file stay as they were.
      #
      # @raise [ TypeError ] If easy is not an Ethon::Easy.
      # @raise [ Ethon::Errors::MultiAdd ] If adding an easy failed.
      def add(easy)
        return nil if easy_handles.include?(easy)
        unless easy.is_a?(Ethon::Easy)
          raise TypeError, "expected an Ethon::Easy, got #{easy.class}"
        end

        # Another Multi may still own the handle natively. Reject before
        # resetting its transfer state or touching its response stream.
        if easy.instance_variable_get(:@multi)
          raise Errors::EthonError, "Easy is still attached to a Multi; remove it first"
        end

        # Resolve every handle before touching the easy so a cleaned up or
        # forked Multi or Easy cannot be changed while raising.
        multi_handle = handle
        easy_handle = easy.handle

        easy_handles << easy
        begin
          code = Curl.multi_add_handle(multi_handle, easy_handle)
        rescue Exception
          # The native add may have completed before a socket or timer callback
          # raised, so make sure libcurl does not keep an untracked handle.
          detach_added_handle(easy, multi_handle, easy_handle)
          raise
        end

        unless code == :ok
          easy_handles.delete(easy)
          raise Errors::MultiAdd.new(code, easy)
        end

        # Cleanup must not free an easy that is still attached to this multi.
        easy.instance_variable_set(:@multi, self)

        # Only a successful add starts a new transfer. Resetting the previous
        # response and opening its output stream before libcurl accepted the
        # handle would make a failed add discard the response body and truncate
        # a streamed response file.
        begin
          easy.prepare_response_body_io
          easy.reset_transfer_state
          easy.clear_callback_error
        rescue Exception
          rollback_add(easy, multi_handle, easy_handle)
          raise
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

      private

      # Undo a native add whose Easy could not be prepared for the transfer.
      def rollback_add(easy, multi_handle, easy_handle)
        begin
          easy.finish_response_body_io
        rescue StandardError
          # Best effort; the add is already being rolled back.
        end

        detach_added_handle(easy, multi_handle, easy_handle)
      end

      # Detach a handle that libcurl may have attached before an exception
      # interrupted the add. The easy stays tracked when it may still be
      # attached so that Multi#cleanup can retry instead of leaving libcurl
      # with an untracked attached handle.
      def detach_added_handle(easy, multi_handle, easy_handle)
        result = begin
          Curl.multi_remove_handle(multi_handle, easy_handle)
        rescue Exception
          nil
        end

        attached = case result
                   when :ok, :bad_easy_handle
                     false
                   when nil
                     # libcurl detaches the easy before it invokes a socket or
                     # timer callback, so a callback exception is not enough to
                     # assume it is still attached.
                     native_handle?(easy_handle)
                   else
                     true
                   end

        if attached
          easy.instance_variable_set(:@multi, self)
        else
          easy_handles.delete(easy)
          easy.instance_variable_set(:@multi, nil)
        end
      end

      # Whether libcurl still knows the native easy handle. libcurl can only
      # answer that question from 7.88.0 on; older versions assume the handle
      # was detached, which matches the order inside Multi#delete.
      def native_handle?(easy_handle)
        return false unless Curl.respond_to?(:multi_get_handles)

        native_handles.any? { |handle| handle == easy_handle }
      rescue NotImplementedError
        false
      end
    end
  end
end
