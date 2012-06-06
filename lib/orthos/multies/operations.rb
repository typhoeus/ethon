module Orthos
  module Multies
    module Operations
      def init_vars
        @timeout = ::FFI::MemoryPointer.new(:long)
        @timeval = Curl::Timeval.new
        @fd_read = Curl::FDSet.new
        @fd_write = Curl::FDSet.new
        @fd_excep = Curl::FDSet.new
        @max_fd = ::FFI::MemoryPointer.new(:int)
      end

      def ongoing?
        easy_handles.size > 0 && (!defined?(@running_count) || running_count > 0)
      end

      def perform
        while ongoing?
          run
          timeout = get_timeout
          next if timeout == 0
          reset_fds
          set_fds(timeout)
        end
      end

      def get_timeout
        code = Curl.multi_timeout(handle, @timeout)
        raise Errors::MultiTimeout.new(code) unless code == :ok
        timeout = @timeout.read_long
        timeout = 1 if timeout < 0
        timeout
      end

      def reset_fds
        @fd_read.clear
        @fd_write.clear
        @fd_excep.clear
      end

      def set_fds(timeout)
        code = Curl.multi_fdset(handle, @fd_read, @fd_write, @fd_excep, @max_fd)
        raise Errors::MultiFdset.new(code) unless code == :ok
        max_fd = @max_fd.read_int
        if max_fd == -1
          sleep(0.001)
        else
          @timeval[:sec] = timeout / 1000
          @timeval[:usec] = (timeout * 1000) % 1000000
          code = Curl.select(max_fd + 1, @fd_read, @fd_write, @fd_excep, @timeval)
          raise Errors::Select.new(::FFI.errno) if code < 0
        end
      end

      def check
        msgs_left = ::FFI::MemoryPointer.new(:int)
        while true
          msg = Curl.multi_info_read(handle, msgs_left)
          break if msg.null?
          next if msg[:code] != :done
          easy = easy_handles.find{ |e| e.handle == msg[:easy_handle] }
          easy.return_code = msg[:data][:code]
          delete(easy)
        end
      end

      def run
        begin code = trigger end while code == :call_multi_perform
        check
      end

      def trigger
        running_count = FFI::MemoryPointer.new(:int)
        code = Curl.multi_perform(handle, running_count)
        @running_count = running_count.read_int
        code
      end

      def running_count
        @running_count ||= nil
      end
    end
  end
end
