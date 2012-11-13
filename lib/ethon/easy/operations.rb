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
        @handle ||= Curl.easy_init
      end

      # Perform the easy request.
      #
      # @example Perform the request.
      #   easy.perform
      #
      # @return [ Integer ] The return code.
      def perform
        @return_code = Curl.easy_perform(handle)
        complete
        Ethon.logger.debug("ETHON: performed #{self.log_inspect}")
        @return_code
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
          "ETHON: It is no longer necessay to call "+
          "Easy#prepare. Its going to be removed "+
          "in future versions."
        )
      end
    end
  end
end
