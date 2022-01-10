# frozen_string_literal: true
module Ethon
  class Easy
    # This module contains the logic to prepare and perform
    # an easy.
    module Operations
      
      class PointerHelper
        class<<self
          def synchronize( &block )
            (@mutex ||= Mutex.new).synchronize( &block )
          end

          def release( pointer )
            synchronize { Curl.easy_cleanup pointer }
          end
        end
        synchronize{}
      end

      # Returns a pointer to the curl easy handle.
      #
      # @example Return the handle.
      #   easy.handle
      #
      # @return [ FFI::Pointer ] A pointer to the curl easy handle.
      def handle
        # @handle ||= FFI::AutoPointer.new(Curl.easy_init, PointerHelper.method(:release) )
        @handle ||= FFI::AutoPointer.new(Curl.easy_init, proc { |pointer| Curl.easy_cleanup(pointer) }) # works for me
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
        @return_code = Curl.easy_perform(handle)
        if Ethon.logger.debug?
          Ethon.logger.debug { "ETHON: performed #{log_inspect}" }
        end
        complete
        @return_code
      end

      # Clean up the easy.
      #
      # @example Perform clean up.
      #   easy.cleanup
      #
      # @return the result of the free which is nil
      def cleanup
        handle.free
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
    end
  end
end
