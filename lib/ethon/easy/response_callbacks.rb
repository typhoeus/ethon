module Ethon
  class Easy

    # This module contains the logic for the response callbacks.
    # The on_complete callback is the only one at the moment.
    #
    # You can set multiple callbacks, which are then executed
    # in the same order.
    #
    #   easy.on_complete { p 1 }
    #   easy.on_complete { p 2 }
    #   easy.complete
    #   #=> 1
    #   #=> 2
    #
    # You can clear the callbacks:
    #
    #   easy.on_complete { p 1 }
    #   easy.on_complete { p 2 }
    #   easy.on_complete.clear
    #   easy.on_complete
    #   #=> []
    module ResponseCallbacks

      # Set on_complete callback.
      #
      # @example Set on_complete.
      #   request.on_complete { p "yay" }
      #
      # @param [ Block ] block The block to execute.
      def on_complete(&block)
        @on_complete ||= []
        @on_complete << block if block_given?
        @on_complete
      end

      # Execute on_complete callbacks.
      #
      # @example Execute on_completes.
      #   request.complete
      def complete
        if defined?(@on_complete)
          @on_complete.each{ |callback| callback.call(self) }
        end
      end
    end
  end
end
