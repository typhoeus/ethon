module Orthos
  class Multi
    class << self
      def finalizer(multi)
        proc {
          Curl.multi_cleanup(multi.handle)
        }
      end
    end

    def initialize
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      @timeout = ::FFI::MemoryPointer.new(:long)
      @timeval = Curl::Timeval.new
      @fd_read = Curl::FDSet.new
      @fd_write = Curl::FDSet.new
      @fd_excep = Curl::FDSet.new
      @max_fd = ::FFI::MemoryPointer.new(:int)
    end

    def handle
      @handle ||= Curl.multi_init
    end

    def easy_handles
      @easy_handles ||= []
    end

    def add(easy)
      return nil if easy_handles.include?(easy)
      code = Curl.multi_add_handle(handle, easy.handle)
      easy_handles << easy
    end

    def delete(easy)
      if easy_handles.delete(easy)
        Curl.multi_remove_handle(handle, easy.handle)
      end
    end

    def running_count
      @running_count
    end

    def perform
      while easy_handles.size > 0
        run
        while running_count > 0
          code = Curl.multi_timeout(handle, @timeout)
          # raise RuntimeError.new(
          #   "an error occured getting the timeout: #{code}: #{Curl.multi_strerror(code)}"
          # ) if code != :ok
          timeout = @timeout.read_long
          if timeout == 0
            run
            next
          elsif timeout < 0
            timeout = 1
          end

          @fd_read.clear
          @fd_write.clear
          @fd_excep.clear
          code = Curl.multi_fdset(handle, @fd_read, @fd_write, @fd_excep, @max_fd)
          # raise RuntimeError.new(
          #   "an error occured getting the fdset: #{code}: #{Curl.multi_strerror(code)}"
          # ) if code != :ok
          max_fd = @max_fd.read_int
          if max_fd == -1
            sleep(0.001)
          else
            @timeval[:sec] = timeout / 1000
            @timeval[:usec] = (timeout * 1000) % 1000000
            code = Curl.select(max_fd + 1, @fd_read, @fd_write, @fd_excep, @timeval)
            # raise RuntimeError.new(
            #   "error on thread select: #{::FFI.errno}"
            # ) if code < 0
          end
          run
        end
      end
    end

    def check
      msgs_left = ::FFI::MemoryPointer.new(:int)
      while not (msg = Curl.multi_info_read(handle, msgs_left)).null?
        next if msg[:code] != :done
        easy = easy_handles.find{ |easy| easy.handle == msg[:easy_handle] }
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
  end
end
