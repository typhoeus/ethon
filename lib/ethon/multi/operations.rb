# frozen_string_literal: true
module Ethon
  class Multi # :nodoc
    # This module contains logic to run a multi.
    module Operations
      STARTED_MULTI = "ETHON: started MULTI"
      PERFORMED_MULTI = "ETHON: performed MULTI"

      # Return the multi handle. Inititialize multi handle,
      # in case it didn't happened already.
      #
      # @example Return multi handle.
      #   multi.handle
      #
      # @return [ FFI::Pointer ] The multi handle.
      def handle
        ensure_not_cleaned_up!

        handle = @handle ||= begin
          pointer = Curl.multi_init
          raise NoMemoryError, "curl_multi_init failed" if pointer.null?
          Curl::MultiHandle.new(pointer)
        end
        handle.check_pid!
        handle
      end

      # Clean up the multi.
      #
      # Removes all attached easy handles before freeing the native multi
      # handle. Cleanup is terminal: the Multi cannot be used afterwards.
      #
      # @return [ nil ]
      def cleanup
        ensure_not_cleaned_up!

        begin
          easy_handles.dup.each { |easy| delete(easy) }
          @handle.free if @handle
        ensure
          @handle = nil
          @assigned_sockets = nil
          @cleaned_up = true
        end
      end

      # Initialize variables.
      #
      # @example Initialize variables.
      #   multi.init_vars
      #
      # @return [ void ]
      def init_vars
        if @execution_mode == :perform
          @timeout = ::FFI::MemoryPointer.new(:long)
          @running_count_pointer = ::FFI::MemoryPointer.new(:int)
          @msgs_left = ::FFI::MemoryPointer.new(:int)
          @wait_strategy = if Curl.respond_to?(:multi_poll)
            :poll
          elsif Curl.respond_to?(:multi_wait)
            :wait
          else
            :select
          end

          if @wait_strategy == :select
            @timeval = Curl::Timeval.new
            @fd_read = Curl::FDSet.new
            @fd_write = Curl::FDSet.new
            @fd_excep = Curl::FDSet.new
            @max_fd = ::FFI::MemoryPointer.new(:int)
          end
        elsif @execution_mode == :socket_action
          @running_count_pointer = FFI::MemoryPointer.new(:int)
          @msgs_left = FFI::MemoryPointer.new(:int)
        end
      end

      # Perform multi.
      #
      # @return [ nil ]
      #
      # @example Perform multi.
      #   multi.perform
      def perform
        ensure_execution_mode(:perform)
        ensure_not_cleaned_up!

        Ethon.logger.debug(STARTED_MULTI)
        while ongoing?
          run
          timeout = get_timeout
          next if timeout == 0
          case @wait_strategy
          when :poll
            poll(timeout)
          when :wait
            wait(timeout)
          else
            reset_fds
            set_fds(timeout)
          end
        end
        Ethon.logger.debug(PERFORMED_MULTI)
        nil
      end

      # Prepare multi.
      #
      # @return [ nil ]
      #
      # @example Prepare multi.
      #   multi.prepare
      #
      # @deprecated It is no longer necessary to call prepare.
      def prepare
        Ethon.logger.warn(
          "ETHON: It is no longer necessay to call "+
          "Multi#prepare. Its going to be removed "+
          "in future versions."
        )
      end

      # Wait for activity on the multi's sockets.
      #
      # @example Wait up to one second.
      #   multi.wait(1000)
      #
      # @param [ Integer ] timeout_ms Maximum time to wait in milliseconds.
      #
      # @return [ Integer ] Number of file descriptors with activity.
      def wait(timeout_ms = 1000)
        unless Curl.respond_to?(:multi_wait)
          raise NotImplementedError, "curl_multi_wait is not supported by this libcurl"
        end

        numfds = (@numfds ||= ::FFI::MemoryPointer.new(:int))
        code = Curl.multi_wait(handle, ::FFI::Pointer::NULL, 0, timeout_ms, numfds)
        raise Errors::MultiWait.new(code) unless code == :ok

        numfds.read_int
      end

      # Wait for activity using curl_multi_poll.
      #
      # @param [ Integer ] timeout_ms Maximum time to wait in milliseconds.
      #
      # @return [ Integer ] Number of file descriptors with activity.
      def poll(timeout_ms = 1000)
        unless Curl.respond_to?(:multi_poll)
          raise NotImplementedError, "curl_multi_poll is not supported by this libcurl"
        end

        numfds = (@numfds ||= ::FFI::MemoryPointer.new(:int))
        code = Curl.multi_poll(handle, ::FFI::Pointer::NULL, 0, timeout_ms, numfds)
        raise Errors::MultiPoll.new(code) unless code == :ok

        numfds.read_int
      end

      # Wake up a multi handle blocked in curl_multi_poll.
      #
      # @return [ Symbol ] The Curl multi return code.
      def wakeup
        unless Curl.respond_to?(:multi_wakeup)
          raise NotImplementedError, "curl_multi_wakeup is not supported by this libcurl"
        end

        code = Curl.multi_wakeup(handle)
        raise Errors::MultiWakeup.new(code) unless code == :ok

        code
      end

      # Continue execution with an external IO loop.
      #
      # @example When no sockets are ready yet, or to begin.
      #   multi.socket_action
      #
      # @example When a socket is readable
      #   multi.socket_action(io_object, [:in])
      #
      # @example When a socket is readable and writable
      #   multi.socket_action(io_object, [:in, :out])
      #
      # @return [ Symbol ] The Curl.multi_socket_action return code.
      def socket_action(io = nil, readiness = 0)
        ensure_execution_mode(:socket_action)
        ensure_not_cleaned_up!

        fd = if io.nil?
          ::Ethon::Curl::SOCKET_TIMEOUT
        elsif io.is_a?(Integer)
          io
        else
          io.fileno
        end

        code = Curl.multi_socket_action(handle, fd, readiness, @running_count_pointer)
        @running_count = @running_count_pointer.read_int

        check

        code
      end

      # Return whether the multi still contains requests or not.
      #
      # @example Return if ongoing.
      #   multi.ongoing?
      #
      # @return [ Boolean ] True if ongoing, else false.
      def ongoing?
        easy_handles.size > 0 || (running_count || 0) > 0
      end

      # Associate an arbitrary pointer with a socket in the multi handle.
      #
      # @param [ Integer, IO ] io The socket descriptor.
      # @param [ FFI::Pointer, nil ] pointer The pointer to associate, or nil
      #   to clear it.
      #
      # @return [ Symbol ] The Curl multi return code.
      def assign(io, pointer)
        unless pointer.nil? || pointer.is_a?(::FFI::Pointer)
          raise Errors::InvalidValue.new(:assign, pointer)
        end

        socket = io.respond_to?(:fileno) ? io.fileno : io
        code = Curl.multi_assign(handle, socket, pointer)
        raise Errors::MultiAssign.new(code) unless code == :ok

        # libcurl keeps the pointer until the socket is removed or assigned
        # again, so keep it alive from Ruby as well.
        if pointer.nil? || pointer.null?
          (@assigned_sockets ||= {}).delete(socket)
        else
          (@assigned_sockets ||= {})[socket] = pointer
        end

        code
      end

      # Return the easy handles currently attached natively.
      #
      # @return [ Array<FFI::Pointer> ] Native easy handles.
      def native_handles
        unless Curl.respond_to?(:multi_get_handles)
          raise NotImplementedError, "curl_multi_get_handles is not supported by this libcurl"
        end

        pointer = Curl.multi_get_handles(handle)
        raise NoMemoryError, "curl_multi_get_handles failed" if pointer.null?

        begin
          handles = []
          offset = 0
          loop do
            easy = pointer.get_pointer(offset)
            break if easy.null?

            handles << easy
            offset += ::FFI.type_size(:pointer)
          end
          handles
        ensure
          Curl.free(pointer)
        end
      end

      private

      def ensure_not_cleaned_up!
        return unless @cleaned_up
        raise Errors::EthonError, "Multi has been cleaned up"
      end

      # Get timeout.
      #
      # @example Get timeout.
      #   multi.get_timeout
      #
      # @return [ Integer ] The timeout.
      #
      # @raise [ Ethon::Errors::MultiTimeout ] If getting the timeout fails.
      def get_timeout
        code = Curl.multi_timeout(handle, @timeout)
        raise Errors::MultiTimeout.new(code) unless code == :ok
        timeout = @timeout.read_long
        timeout = 1 if timeout < 0
        timeout
      end

      # Reset file describtors.
      #
      # @example Reset fds.
      #   multi.reset_fds
      #
      # @return [ void ]
      def reset_fds
        @fd_read.clear
        @fd_write.clear
        @fd_excep.clear
      end

      # Set fds.
      #
      # @example Set fds.
      #   multi.set_fds
      #
      # @return [ void ]
      #
      # @raise [ Ethon::Errors::MultiFdset ] If setting the file descriptors fails.
      # @raise [ Ethon::Errors::Select ] If select fails.
      def set_fds(timeout)
        code = Curl.multi_fdset(handle, @fd_read, @fd_write, @fd_excep, @max_fd)
        raise Errors::MultiFdset.new(code) unless code == :ok
        max_fd = @max_fd.read_int
        if max_fd == -1
          sleep(0.001)
        else
          @timeval[:sec] = timeout / 1000
          @timeval[:usec] = (timeout * 1000) % 1000000
          loop do
            code = Curl.select(max_fd + 1, @fd_read, @fd_write, @fd_excep, @timeval)
            break unless code < 0 && ::FFI.errno == Errno::EINTR::Errno
          end
          raise Errors::Select.new(::FFI.errno) if code < 0
        end
      end

      # Check.
      #
      # @example Check.
      #   multi.check
      #
      # @return [ void ]
      def check
        msgs_left = (@msgs_left ||= ::FFI::MemoryPointer.new(:int))
        while true
          msg = Curl.multi_info_read(handle, msgs_left)
          break if msg.null?
          next if msg[:code] != :done
          easy = easy_handles.find{ |e| e.handle == msg[:easy_handle] }
          # The handle may have been removed between the transfer finishing and
          # the completion message being read.
          next unless easy
          easy.return_code = msg[:data][:code]
          Ethon.logger.debug { "ETHON:         performed #{easy.log_inspect}" }
          delete(easy)
          easy.complete
          easy.raise_callback_error
        end
      end

      # Run.
      #
      # @example Run
      #   multi.run
      #
      # @return [ void ]
      def run
        running_count_pointer = (@running_count_pointer ||= ::FFI::MemoryPointer.new(:int))
        begin code = trigger(running_count_pointer) end while code == :call_multi_perform
        raise Errors::MultiPerform.new(code) unless code == :ok

        check
      end

      # Trigger.
      #
      # @example Trigger.
      #   multi.trigger
      #
      # @return [ Symbol ] The Curl.multi_perform return code.
      def trigger(running_count_pointer)
        code = Curl.multi_perform(handle, running_count_pointer)
        @running_count = running_count_pointer.read_int
        code
      end

      # Return number of running requests.
      #
      # @example Return count.
      #   multi.running_count
      #
      # @return [ Integer ] Number running requests.
      def running_count
        @running_count
      end
    end
  end
end
