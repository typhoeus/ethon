module Ethon
  module Easies
    module ResponseCallbacks
      def trigger_callbacks
        success if success?
        failure if failure?
      end

      # Return wether the request was successful.
      # Curls return code needs to be 0 and the response
      # code between 200 and 299.
      #
      # @example Was request successful?
      #   easy.success?
      #
      # @return [ Boolean ] True if request successful, false else.
      def success?
        return_code == 0 && [0, *(200..299)].include?(response_code)
      end

      # Return wether the request failed.
      # Returns the opposite of successful?.
      #
      # @example Did request failes?
      #   easy.failure?
      #
      # @return [ Boolean ] True if request failed, false else.
      def failure?
        !success?
      end

      # Execute preset success callback.
      #
      # @example Execute success callback.
      #   easy.success
      def success
        return if !defined?(@success) || @success.nil?
        @success.call(self)
      end

      # Set success callback.
      #
      # @example Set success callback.
      #   easy.on_success = block
      def on_success(&block)
        @success = block
      end

      # Execute preset failure callback.
      #
      # @example Execute failure callback.
      #   easy.failure
      def failure
        return if !defined?(@failure) || @failure.nil?
        @failure.call(self)
      end

      # Set failure callback.
      #
      # @example Set failure callback.
      #   easy.on_failure = block
      def on_failure(&block)
        @failure = block
      end
    end
  end
end
