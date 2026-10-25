# frozen_string_literal: true
module Ethon
  class Easy
    # This module contains the logic to prepare and perform
    # an easy.
    module Operations
      # Returns a pointer to the curl easy handle.
      #
      # @example Return the handle.
      #   easy.handle
      #
      # @return [ FFI::Pointer ] A pointer to the curl easy handle.
      def handle
        raise Errors::EthonError, "Easy has been cleaned up" if @cleaned_up

        @handle ||= create_handle
        handle = @handle
        handle.check_pid!
        handle.owner ||= self
        handle
      end

      # Sets a pointer to the curl easy handle.
      #
      # Raw pointers are wrapped in an owned {Curl::EasyHandle}, so the
      # handle is registered for fork safety and freed by this Easy. Assigning
      # nil installs a fresh handle. Assigning a different handle installs
      # Ethon's response callbacks and replays callbacks previously assigned to
      # this Easy, then frees the handle it replaces when this Easy owned it.
      #
      # @param [ ::FFI::Pointer, Curl::EasyHandle, nil ] Easy handle that will
      #   be assigned.
      def handle=(h)
        raise Errors::EthonError, "Easy has been cleaned up" if @cleaned_up

        ensure_not_performing!
        ensure_not_attached_to_multi!

        previous = @handle
        @handle =
          case h
          when nil
            # Create the replacement now so it gets Ethon's callbacks even
            # before an option setter or #perform touches it.
            create_handle
          when Curl::EasyHandle
            h.check_pid!
            # Two Easies must not share one owned wrapper: whichever cleans up
            # first invalidates the handle for the other.
            if h.owner && !h.owner.equal?(self)
              raise ArgumentError, "easy handle is already owned by another Ethon handle"
            end
            h
          when Curl::OwnedPointer
            raise TypeError, "expected an easy handle, got #{h.class}"
          when ::FFI::Pointer
            raise ArgumentError, "cannot assign a null easy handle" if h.null?

            Curl::EasyHandle.new(h)
          else
            raise TypeError, "expected an easy handle pointer, got #{h.class}"
          end
        @handle.owner = self if @handle
        if @handle && !@handle.equal?(previous)
          # A replacement handle has no Ethon callbacks or Ethon-managed
          # options, so its response would otherwise not be collected. Retained
          # user callbacks are replayed on top of the internal ones.
          install_callbacks(@handle)
          restore_handle_options
          restore_callbacks_on(self)
        end
        release_replaced_handle(previous)
        @handle
      end

      # Perform the easy request.
      #
      # @example Perform the request.
      #   easy.perform
      #
      # @return [ Integer ] The return code.
      def perform
        ensure_not_performing!
        # curl_easy_perform must not drive a handle that is owned by a multi.
        ensure_not_attached_to_multi!
        # Touch the handle before changing transfer state so a cleaned up or
        # forked handle cannot truncate a response file or reset the previous
        # result while raising.
        handle

        prepare_response_body_io
        reset_transfer_state
        clear_callback_error
        # Only the destination that belongs to this transfer may be finished.
        # A completion callback can install the next transfer's destination.
        response_body_io = @response_body_io
        @performing = true

        error = nil
        begin
          code = Curl.easy_perform(handle)
          @return_code = code
          if Ethon.logger.debug?
            Ethon.logger.debug { "ETHON: performed #{log_inspect}" }
          end
          # Make the complete response visible before on_complete runs. An
          # owned file is closed by the ensure below after the callbacks.
          begin
            flush_response_body_io
          rescue Exception
            # A callback error already failed this transfer; a flush error is
            # secondary and must not hide it.
            raise_callback_error
            raise
          end
          complete
          raise_callback_error
          # on_complete may reset the Easy, which clears @return_code. Return
          # the result of the transfer that just ran.
          code
        rescue Exception => exception
          error = exception
          raise
        ensure
          @performing = false
          begin
            finish_response_body_io(response_body_io)
          rescue Exception
            # Keep the exception that interrupted the transfer or completion.
            raise unless error
          end
        end
      end

      # Clean up the easy.
      #
      # Cleanup is terminal: the native handle is freed and the Easy cannot be
      # used again. Reusing it raises Ethon::Errors::EthonError.
      #
      # @example Perform clean up.
      #   easy.cleanup
      #
      # @return the result of the free which is nil
      def cleanup
        ensure_not_performing!
        ensure_not_attached_to_multi!

        # Resolve the handle first: cleanup must not clear the response body if
        # the handle is unusable (cleaned up or inherited across a fork).
        handle_to_free = handle
        begin
          clear_response_body_io
        ensure
          # Free the native handle even when closing the response body fails.
          begin
            handle_to_free.free
          ensure
            clear_native_state
            @handle = nil
            @cleaned_up = true
          end
        end
      end

      # Prepare the easy. Options, headers and callbacks
      # were set.
      #
      # @example Prepare easy.
      #   easy.prepare
      #
      # @deprecated It is no longer necessary to call prepare.
      def prepare
        Ethon.logger.warn(
          "ETHON: It is no longer necessary to call "+
          "Easy#prepare. It's going to be removed "+
          "in future versions."
        )
      end

      private

      # Allocate the native handle. Kept separate so #handle= can replace a
      # handle and install the callbacks before the next option setter runs.
      def create_handle
        Curl.check_pid!
        pointer = Curl.easy_init
        raise NoMemoryError, "curl_easy_init failed" if pointer.null?
        Curl::EasyHandle.new(pointer)
      end

      # Reapply options Ethon installed on the old handle. These are not user
      # request options: without them #error_message and progress callbacks
      # silently stop working on the replacement.
      def restore_handle_options
        if @error_buffer_enabled && @error_buffer
          Curl.set_option(:errorbuffer, @error_buffer, @handle)
          @handle.error_buffer = @error_buffer
          # Do not report the previous transfer's error from the new handle.
          @error_buffer.put_char(0, 0)
        end
        self.noprogress = @noprogress_value unless @noprogress_value.nil?
      end

      # Free the handle this Easy owned before the replacement. A handle owned
      # by another Easy (the source of #dup) must stay alive for its owner.
      def release_replaced_handle(previous)
        return unless previous
        return if previous.equal?(@handle)
        return unless previous.owner.equal?(self)

        previous.free
      end

      # Drop references to native data and callbacks once the handle is gone.
      def clear_native_state
        @body_write_callback = nil
        @header_write_callback = nil
        @debug_callback = nil
        @progress_callback = nil
        @read_callback = nil
        @request_body = nil
        @request_body_start = nil
        @postfields = nil
        @postfields_pointer = nil
        @header_list = nil
        @multipart_form = nil
        @mime = nil
        @curlu = nil
        @blobs = nil
        @slists = nil
        @procs = nil
        @on_complete = nil
        @on_headers = nil
        @on_body = nil
        @on_progress = nil
        @progress_source = nil
        @internal_progress_option = nil
        @user_debug_callback = nil
        @share = nil
        @error_buffer = nil
        @error_buffer_enabled = nil
        @noprogress_value = nil
      end

      def ensure_not_performing!
        if @completing
          raise Errors::EthonError, "Easy is currently completing; wait for the callbacks to finish"
        end
        if @performing
          raise Errors::EthonError, "Easy is currently performing; wait for the transfer to finish"
        end
      end

      # Resetting is safe from a completion callback: the transfer has already
      # finished and the handle no longer belongs to a Multi. A reset from a
      # body, header, or progress callback still runs inside libcurl.
      def ensure_not_in_transfer!
        return if @completing

        ensure_not_performing!
      end

      def ensure_not_attached_to_multi!
        return unless defined?(@multi) && @multi

        raise Errors::EthonError, "Easy is still attached to a Multi; remove it first"
      end
    end
  end
end
