# frozen_string_literal: true
module Ethon
  class Easy
    # This module contains logic for streaming response bodies to Ruby IOs.
    module Files
      # Stream the response body to a path or writable Ruby object. Ethon closes
      # files it opens from paths; caller-provided objects remain caller-owned.
      # Pass nil to restore in-memory response buffering.
      def file=(destination)
        # Resolve the handle first. Opening a path truncates it, so a cleaned
        # up or fork-inherited handle must not touch the destination before the
        # error is raised.
        handle
        clear_response_body_io
        # Pathname-like objects may also implement #write. Prefer the path when
        # the object is not an IO (File and Tempfile expose #fileno).
        if destination.respond_to?(:to_path) && !destination.respond_to?(:fileno)
          @response_body_path = destination.to_path
          prepare_response_body_io
        elsif destination.respond_to?(:write)
          @response_body_io = destination
          @owns_response_body_io = false
        elsif destination
          @response_body_path = destination.to_s
          prepare_response_body_io
        end
        @response_body = @response_body_io ? nil : String.new
        destination
      end

      alias writedata= file=

      def prepare_response_body_io
        return unless @response_body_path && !@response_body_io

        @response_body_io = File.open(@response_body_path, "wb")
        @owns_response_body_io = true
      end

      def close_response_body_io
        @response_body_io.close if @owns_response_body_io && @response_body_io && !@response_body_io.closed?
        @response_body_io = nil
        @owns_response_body_io = false
      end

      def clear_response_body_io
        close_response_body_io
        @response_body_path = nil
      end

      def finish_response_body_io
        return unless @owns_response_body_io

        close_response_body_io
      end
    end
  end
end
