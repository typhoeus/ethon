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

        path, io, owned = response_body_destination(destination)
        previous_io = @response_body_io
        previous_owned = @owns_response_body_io

        # Open the new destination before closing the previous one so a path
        # that cannot be opened leaves the Easy with its previous stream.
        begin
          if previous_owned && previous_io && !previous_io.equal?(io) && !previous_io.closed?
            previous_io.close
          end
        rescue Exception
          begin
            io.close if owned && io && !io.equal?(previous_io) && !io.closed?
          rescue StandardError
            # Keep the error from closing the previous destination.
          end
          raise
        end

        @response_body_io = io
        @response_body_path = path
        @owns_response_body_io = owned
        @response_body = io ? nil : String.new
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

      # Flush buffered writes without closing a caller-owned IO. Response
      # callbacks and readers should see the complete body before the transfer
      # is treated as finished.
      def flush_response_body_io
        io = @response_body_io
        return unless io
        return if io.respond_to?(:closed?) && io.closed?

        io.flush if io.respond_to?(:flush)
      end

      # Finish the destination used by one transfer. A completion callback may
      # already have installed the destination for the next transfer; only the
      # stream this transfer wrote to belongs to it.
      #
      # @param [ IO, nil ] io The destination that transfer used.
      def finish_response_body_io(io = @response_body_io)
        return unless @response_body_io && @response_body_io.equal?(io)

        if @owns_response_body_io
          close_response_body_io
        else
          flush_response_body_io
        end
      end

      private

      # Resolve a destination to [path, io, owned] without touching the Easy's
      # current stream. Pathname-like objects may also implement #write. Prefer
      # the path when the object is not an IO (File and File-like objects with
      # #fileno).
      def response_body_destination(destination)
        if destination.respond_to?(:to_path) && !destination.respond_to?(:fileno)
          path = destination.to_path
          [path, File.open(path, "wb"), true]
        elsif destination.respond_to?(:write)
          [nil, destination, false]
        elsif destination
          path = destination.to_s
          [path, File.open(path, "wb"), true]
        else
          [nil, nil, false]
        end
      end
    end
  end
end
