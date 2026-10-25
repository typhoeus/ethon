# frozen_string_literal: true
module Ethon
  class Easy

    # This module contains all the logic around the callbacks,
    # which are needed to interact with libcurl.
    #
    # @api private
    module Callbacks

      # :nodoc:
      def self.included(base)
        base.send(:attr_accessor, *[:response_body, :response_headers, :debug_info])
      end

      # Set writefunction and headerfunction callback.
      # They are called by libcurl in order to provide the header and
      # the body from the request.
      #
      # @example Set callbacks.
      #   easy.set_callbacks
      def set_callbacks
        install_callbacks(handle)
        reset_transfer_state
      end

      # Reset the state that belongs to a single transfer. Reusing an Easy must
      # replace the previous response instead of appending to it.
      def reset_transfer_state
        rewind_request_body
        @response_body = @response_body_io ? nil : String.new
        @response_headers = String.new
        @headers_called = false
        @debug_info = Ethon::Easy::DebugInfo.new
        @request_body_read = 0
        @return_code = nil
      end

      # Returns the body write callback.
      #
      # @example Return the callback.
      #   easy.body_write_callback
      #
      # @return [ Proc ] The callback.
      def body_write_callback
        @body_write_callback ||= proc do |stream, size, num, object|
          begin
            headers_user_callback_result = headers
            result = body(chunk = stream.read_string(size * num))
            if @response_body_io && result != :abort && headers_user_callback_result != :abort
              write_response_body(@response_body_io, chunk)
            elsif result == :unyielded && !@response_body_io && headers_user_callback_result != :abort
              @response_body << chunk
            end
            (result != :abort && headers_user_callback_result != :abort) ? size * num : -1
          rescue Exception => e
            @callback_error ||= e
            0
          end
        end
      end

      # Returns the header write callback.
      #
      # @example Return the callback.
      #   easy.header_write_callback
      #
      # @return [ Proc ] The callback.
      def header_write_callback
        @header_write_callback ||= proc {|stream, size, num, object|
          begin
            @response_headers << stream.read_string(size * num)
            size * num
          rescue Exception => e
            @callback_error ||= e
            0
          end
        }
      end

      # This callback is called for every debug message libcurl emits while
      # verbose mode is enabled.
      #
      # Messages are written through +Ethon.logger+ at the debug level. The
      # user observer registered with #debugfunction is called as well.
      #
      # @example Return the callback.
      #   easy.debug_callback
      #
      # @return [ Proc ] The callback.
      def debug_callback
        @debug_callback ||= proc {|handle, type, data, size, udata|
          begin
            message = data.read_string(size)
            @debug_info.add type, message

            if [:ssl_data_in, :ssl_data_out].include?(type)
              log_debug("[#{size} bytes data]")
            elsif [:data_in, :data_out].include?(type)
              # Body data stays in #debug_info; logging it would duplicate the
              # response body in the application log.
            else
              log_debug(message)
            end
            @user_debug_callback.call(handle, type, data, size, udata) if @user_debug_callback
          rescue Exception => e
            @callback_error ||= e
          end
          0
        }
      end

      def set_progress_callback
        # CURLOPT_XFERINFOFUNCTION was added in libcurl 7.32.0.
        option = if Curl.version_at_least?("7.32.0")
          :xferinfofunction
        else
          :progressfunction
        end
        Curl.set_option(option, progress_callback, handle)
        # Remember which callback is effective so a duplicate can restore it.
        @progress_source = :internal
        @internal_progress_option = option
      end

      # Returns the progress callback.
      #
      # @example Return the callback.
      #   easy.progress_callback
      #
      # @return [ Proc ] The callback.
      def progress_callback
        @progress_callback ||= proc do |_, dltotal, dlnow, ultotal, ulnow|
          begin
            progress(dltotal, dlnow, ultotal, ulnow)
            0
          rescue Exception => e
            @callback_error ||= e
            0
          end
        end
      end

      # A completion callback may start the next transfer on this Easy. Keep
      # the finished transfer's callback error so the caller still sees it;
      # the next transfer starts without it once the error is raised.
      def clear_callback_error
        @callback_error = nil unless @completing
      end

      # The transfer teardown in #perform, #complete, and Multi#check already
      # finishes the response stream. Finishing it here again could close a
      # stream a completion callback installed for the next transfer, or
      # replace the callback error with a teardown error.
      def raise_callback_error
        return unless @callback_error

        error = @callback_error
        @callback_error = nil
        raise error
      end

      # Set the read callback. This callback is used by libcurl to
      # read data when performing a PUT request.
      #
      # @example Set the callback.
      #   easy.set_read_callback("a=1")
      #
      # @param [ String ] body The body.
      def set_read_callback(body)
        @request_body_read = 0
        @request_body = body
        # Remember where a seekable body starts so reusing the Easy replays the
        # same range instead of finding the IO at EOF.
        @request_body_start = begin
          body.pos if body.respond_to?(:seek) && body.respond_to?(:pos)
        rescue IOError, SystemCallError
          nil
        end
        @read_callback = proc do |stream, size, num, object|
          begin
            size = size * num
            remaining = if body.respond_to?(:byteslice)
              body.bytesize - @request_body_read
            elsif body.respond_to?(:read)
              # IO-like bodies advance their own position.
              body.size - body.pos if body.respond_to?(:size) && body.respond_to?(:pos)
            elsif body.respond_to?(:size)
              body.size - @request_body_read
            end

            size = remaining if remaining && size > remaining

            chunk = if size > 0
              if body.respond_to?(:byteslice)
                body.byteslice(@request_body_read, size)
              elsif body.respond_to?(:read)
                body.read(size)
              else
                body[@request_body_read, size]
              end
            end

            # libcurl expects the number of bytes actually copied into the
            # buffer. IO-like bodies may return fewer bytes than requested.
            chunk_size = chunk ? chunk.bytesize : 0
            if chunk_size > 0
              stream.write_string(chunk, chunk_size)
              @request_body_read += chunk_size
            end
            chunk_size
          rescue Exception => e
            @callback_error ||= e
            0
          end
        end
        readfunction(&@read_callback)
      end

      # Returns the body read callback.
      #
      # @example Return the callback.
      #   easy.read_callback
      #
      # @return [ Proc ] The callback.
      def read_callback
        @read_callback
      end

      private

      # IO#write may accept fewer bytes than it was given, especially for
      # nonblocking or wrapper IOs. libcurl must only see the chunk as handled
      # once every byte reached the destination. IOs that return nil (or a
      # non-integer) keep the historical "wrote everything" behavior.
      def write_response_body(io, chunk)
        offset = 0
        total = chunk.bytesize
        while offset < total
          pending = offset.zero? ? chunk : chunk.byteslice(offset, total - offset)
          written = io.write(pending)
          return unless written.is_a?(Integer)

          raise IOError, "response body write made no progress" if written <= 0
          offset += written
        end
      end

      # Install the callbacks that fill the Ruby-side response state. The
      # handle is passed explicitly so callers do not have to go through
      # #handle, which would create a handle as a side effect.
      def install_callbacks(target)
        Curl.set_option(:writefunction, body_write_callback, target)
        Curl.set_option(:headerfunction, header_write_callback, target)
        Curl.set_option(:debugfunction, debug_callback, target)
      end

      # Log a libcurl debug message through Ethon.logger. The default level is
      # INFO, so applications opt in by lowering the logger level.
      def log_debug(message)
        return if message.empty?

        logger = Ethon.logger
        return unless logger.debug?

        logger.debug { message.sub(/\n+\z/, "") }
      end

      # Seek a request body back to where it was when the callback was
      # installed. Pipes and other non-seekable bodies are left alone.
      def rewind_request_body
        return unless @request_body_start
        return unless @request_body.respond_to?(:seek)

        @request_body.seek(@request_body_start)
      rescue IOError, SystemCallError
        nil
      end
    end
  end
end
