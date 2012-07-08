module Ethon
  module Easies
    # This module contains the logic to prepare and perform
    # an easy.
    module Operations

      # Perform the easy request.
      #
      # @example Perform the request.
      #   easy.perform
      #
      # @return [ Integer ] The return code.
      def perform
        @return_code = Curl.easy_perform(handle)
        complete
        @return_code
      end

      # Returns a  pointer to the curl easy handle.
      #
      # @example Return the handle.
      #   easy.handle
      #
      # @return [ FFI::Pointer ] A pointer to the curl easy handle.
      def handle
        @handle ||= Curl.easy_init
      end

      # Prepare the easy. Options, headers and callbacks
      # were set.
      #
      # @example Prepare easy.
      #   easy.prepare
      def prepare
        set_options
        set_headers
        set_callbacks
      end
    end
  end
end
