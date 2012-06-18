module Ethon
  module Easies

    # This module contains the logic for the response callbacks.
    # The on_complete callback is the only one at the moment.
    module ResponseCallbacks
      # Execute preset complete callback.
      #
      # @example Execute complete callback.
      #   easy.complete
      def complete
        return if !defined?(@complete) || @complete.nil?
        @complete.call(self)
      end

      # Set complete callback.
      #
      # @example Set complete callback.
      #   easy.on_complete = block
      def on_complete(&block)
        @complete = block
      end
    end
  end
end
