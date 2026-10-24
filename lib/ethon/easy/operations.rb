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

        handle = @handle ||= begin
          pointer = Curl.easy_init
          raise NoMemoryError, "curl_easy_init failed" if pointer.null?
          Curl::EasyHandle.new(pointer)
        end
        handle.check_pid!
        handle
      end

      # Sets a pointer to the curl easy handle.
      # @param [ ::FFI::Pointer ] Easy handle that will be assigned.
      def handle=(h)
        @handle = h
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

        prepare_response_body_io
        reset_transfer_state
        clear_callback_error
        @performing = true

        begin
          @return_code = Curl.easy_perform(handle)
          if Ethon.logger.debug?
            Ethon.logger.debug { "ETHON: performed #{log_inspect}" }
          end
          complete
          raise_callback_error
          @return_code
        ensure
          @performing = false
          finish_response_body_io
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

        begin
          clear_response_body_io
          handle.free
        ensure
          @handle = nil
          @cleaned_up = true
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

      def ensure_not_performing!
        if @completing
          raise Errors::EthonError, "Easy is currently completing; wait for the callbacks to finish"
        end
        if @performing
          raise Errors::EthonError, "Easy is currently performing; wait for the transfer to finish"
        end
      end

      def ensure_not_attached_to_multi!
        return unless defined?(@multi) && @multi

        raise Errors::EthonError, "Easy is still attached to a Multi; remove it first"
      end
    end
  end
end
