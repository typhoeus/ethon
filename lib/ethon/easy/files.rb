 # frozen_string_literal: true
module Ethon
  class Easy
    # This module contains logic for streaming response bodies to Ruby IOs.
    module Files
      def file=(destination)
        close_response_body_io
        if destination.respond_to?(:write)
          @response_body_io = destination
          @owns_response_body_io = false
        elsif destination
          @response_body_io = File.open(destination.to_path, "wb")
          @owns_response_body_io = true
        end
        @response_body = @response_body_io ? nil : String.new
        destination
      end

      alias writedata= file=

      def close_response_body_io
        @response_body_io.close if @owns_response_body_io && @response_body_io && !@response_body_io.closed?
        @response_body_io = nil
        @owns_response_body_io = false
      end

      def finish_response_body_io
        return unless @owns_response_body_io

        close_response_body_io
      end
    end
  end
end
