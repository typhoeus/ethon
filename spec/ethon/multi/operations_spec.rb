# frozen_string_literal: true
require 'spec_helper'
require 'stringio'
require 'tmpdir'

describe Ethon::Multi::Operations do
  let(:multi) { Ethon::Multi.new }
  let(:easy) { Ethon::Easy.new }
  let(:pointer) { FFI::MemoryPointer.new(:int) }

  after do
    multi.easy_handles.grep(Ethon::Easy).each { |handle| multi.delete(handle) }
  end

  describe "#handle" do
    it "returns a pointer" do
      expect(multi.handle).to be_a(FFI::Pointer)
    end

    it "raises when multi_init returns a null pointer" do
      expect(Ethon::Curl).to receive(:multi_init).and_return(FFI::Pointer::NULL)

      expect { multi.handle }.to raise_error(NoMemoryError, "curl_multi_init failed")
    end

    it "rejects a handle inherited across a fork" do
      multi.handle
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          multi.handle
        rescue Exception => e
          writer.write(e.class.name)
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("Ethon::Errors::ForkSafety")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "rejects creating a handle after a fork" do
      # Creating the Multi initializes libcurl in the parent, but this Multi
      # does not allocate its native handle until #handle is called.
      expect(multi.instance_variable_get(:@handle)).to be_nil
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          multi.handle
        rescue Exception => e
          writer.write(e.class.name)
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("Ethon::Errors::ForkSafety")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end
  end

  describe "#cleanup" do
    it "removes attached easy handles" do
      easy.url = "http://127.0.0.1:3001/"
      multi.add(easy)

      multi.cleanup

      expect(multi.easy_handles).to be_empty
      expect(easy.instance_variable_get(:@multi)).to be_nil
    end

    it "frees the native handle" do
      multi.handle

      multi.cleanup

      expect { multi.handle }.to raise_error(Ethon::Errors::EthonError, /cleaned up/)
    end

    it "is terminal" do
      multi.cleanup

      expect { multi.perform }.to raise_error(Ethon::Errors::EthonError, /cleaned up/)
    end

    it "rejects a second cleanup" do
      multi.cleanup

      expect { multi.cleanup }.to raise_error(Ethon::Errors::EthonError, /cleaned up/)
    end

    it "rejects cleaning up a handle inherited across a fork" do
      multi.handle
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          multi.cleanup
        rescue Exception => e
          writer.write(e.class.name)
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("Ethon::Errors::ForkSafety")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end
  end

  describe "reentrancy" do
    it "refuses to clean up while executing" do
      multi.instance_variable_set(:@executing, true)

      expect { multi.cleanup }.
        to raise_error(Ethon::Errors::EthonError, /executing/)
    end

    it "refuses to perform while executing" do
      multi.instance_variable_set(:@executing, true)

      expect { multi.perform }.
        to raise_error(Ethon::Errors::EthonError, /executing/)
    end

    it "refuses to clean up from an on_complete callback" do
      easy.url = "http://127.0.0.1:3001/"
      easy.on_complete { multi.cleanup }
      multi.add(easy)

      expect { multi.perform }.
        to raise_error(Ethon::Errors::EthonError, /executing/)
    ensure
      multi.cleanup unless multi.instance_variable_get(:@cleaned_up)
    end
  end

  describe "#running_count" do
    context "when hydra has no easy" do
      it "returns nil" do
        expect(multi.send(:running_count)).to be_nil
      end
    end

    context "when hydra has easy" do
      before do
        easy.url = "http://127.0.0.1:3001/"
        multi.add(easy)
        multi.send(:trigger, pointer)
      end

      it "returns 1" do
        expect(multi.send(:running_count)).to eq(1)
      end
    end

    context "when hydra has more easys" do
      let(:another_easy) { Ethon::Easy.new }

      before do
        easy.url = "http://127.0.0.1:3001/"
        another_easy.url = "http://127.0.0.1:3001/"
        multi.add(easy)
        multi.add(another_easy)
        multi.send(:trigger, pointer)
      end

      it "returns 2" do
        expect(multi.send(:running_count)).to eq(2)
      end
    end
  end

  describe "#get_timeout" do
    context "when code ok" do
      let(:timeout) { 1 }

      before do
        expect(Ethon::Curl).to receive(:multi_timeout).and_return(:ok)
        multi.instance_variable_set(:@timeout, double(:read_long => timeout))
      end

      it "doesn't raise" do
        expect{ multi.send(:get_timeout) }.to_not raise_error
      end

      context "when timeout smaller zero" do
        let(:timeout) { -1 }

        it "returns 1" do
          expect(multi.send(:get_timeout)).to eq(1)
        end
      end

      context "when timeout bigger or equal zero" do
        let(:timeout) { 2 }

        it "returns timeout" do
          expect(multi.send(:get_timeout)).to eq(timeout)
        end
      end
    end

    context "when code not ok" do
      before { expect(Ethon::Curl).to receive(:multi_timeout).and_return(:not_ok) }

      it "raises MultiTimeout error" do
        expect{ multi.send(:get_timeout) }.to raise_error(Ethon::Errors::MultiTimeout)
      end
    end
  end

  describe "#set_fds" do
    let(:timeout) { 1 }
    let(:max_fd) { 1 }

    before do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_poll).and_return(false)
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_wait).and_return(false)
      multi.init_vars
    end

    context "when code ok" do
      before { expect(Ethon::Curl).to receive(:multi_fdset).and_return(:ok) }

      it "doesn't raise" do
        expect{ multi.method(:set_fds).call(timeout) }.to_not raise_error
      end

      context "when max_fd -1" do
        let(:max_fd) { -1 }

        before do
          multi.instance_variable_set(:@max_fd, double(:read_int => max_fd))
        end

        it "waits for the timeout" do
          expect(multi).to receive(:sleep).with(0.001)
          multi.method(:set_fds).call(timeout)
        end

        context "when the timeout is longer" do
          let(:timeout) { 250 }

          it "does not busy-wait" do
            expect(multi).to receive(:sleep).with(0.25)
            multi.method(:set_fds).call(timeout)
          end
        end
      end

      context "when max_fd not -1" do
        context "when code smaller zero" do
          before { expect(Ethon::Curl).to receive(:select).and_return(-1) }

          it "raises Select error" do
            expect{ multi.method(:set_fds).call(timeout) }.to raise_error(Ethon::Errors::Select)
          end
        end

        context "when code bigger or equal zero" do
          before { expect(Ethon::Curl).to receive(:select).and_return(0) }

          it "doesn't raise" do
            expect{ multi.method(:set_fds).call(timeout) }.to_not raise_error
          end
        end
      end
    end

    context "when code not ok" do
      before { expect(Ethon::Curl).to receive(:multi_fdset).and_return(:not_ok) }

      it "raises MultiFdset error" do
        expect{ multi.method(:set_fds).call(timeout) }.to raise_error(Ethon::Errors::MultiFdset)
      end
    end
  end

  describe "#perform" do
    context "when no easy handles" do
      it "returns nil" do
        expect(multi.perform).to be_nil
      end

      it "logs" do
        expect(Ethon.logger).to receive(:debug).twice
        multi.perform
      end
    end

    context "when easy handle" do
      before do
        easy.url = "http://127.0.0.1:3001/"
        multi.add(easy)
      end

      it "requests" do
        multi.perform
      end

      it "sets easy" do
        multi.perform
        expect(easy.response_code).to eq(200)
      end

      it "waits with curl_multi_poll when available" do
        skip "curl_multi_poll is unavailable" unless Ethon::Curl.respond_to?(:multi_poll)

        easy.url = "http://127.0.0.1:3001/?delay=0.05"
        expect(multi).to receive(:poll).at_least(:once).and_call_original

        multi.perform
      end

      it "raises callback exceptions with verbose output enabled" do
        easy.verbose = true
        error = RuntimeError.new("body callback failed")
        easy.on_body { raise error }

        expect { multi.perform }.to raise_error(error)
      end

      it "completes and removes the easy before raising callback exceptions" do
        completed = false
        error = RuntimeError.new("body callback failed")
        easy.on_body { raise error }
        easy.on_complete { completed = true }

        expect { multi.perform }.to raise_error(error)
        expect(completed).to be(true)
        expect(multi.easy_handles).not_to include(easy)
      end

      it "raises debug callback exceptions" do
        easy.verbose = true
        error = RuntimeError.new("debug callback failed")
        easy.debugfunction { raise error }

        expect { multi.perform }.to raise_error(error)
      end

      it "completes and removes the easy before raising progress exceptions" do
        completed = false
        error = RuntimeError.new("progress callback failed")
        easy.on_progress { raise error }
        easy.on_complete { completed = true }

        expect { multi.perform }.to raise_error(error)
        expect(completed).to be(true)
        expect(multi.easy_handles).not_to include(easy)
      end

      it "streams the response to a caller-owned IO" do
        io = StringIO.new
        easy.file = io

        multi.perform

        expect(io.string).to include('"REQUEST_METHOD":"GET"')
        expect(io).not_to be_closed
      end

      it "replaces the response when the same easy is added again" do
        multi.perform

        easy.url = "http://127.0.0.1:3001/second"
        multi.add(easy)
        multi.perform

        expect(easy.response_body).to include('"PATH_INFO":"/second"')
        expect(easy.response_body.scan('"GATEWAY_INTERFACE"').size).to eq(1)
        expect(easy.response_headers.scan("HTTP/1.1").size).to eq(1)
      end
    end

    context "when four easy handles" do
      let(:easies) do
        ary = []
        4.times do
          ary << another_easy = Ethon::Easy.new
          another_easy.url = "http://127.0.0.1:3001/"
        end
        ary
      end

      before do
        easies.each { |e| multi.add(e) }
        multi.perform
      end

      it "sets response codes" do
        expect(easies.all?{ |e| e.response_code == 200 }).to be_truthy
      end
    end

    context "when libcurl blocks inside curl_multi_perform" do
      # A file:// read of a FIFO blocks in open() until the writer shows up. A resolver thread stuck
      # in getaddrinfo blocks curl_multi_perform the same way when libcurl joins it on timeout.
      it "lets other threads run" do
        Dir.mktmpdir do |dir|
          fifo = File.join(dir, "fifo")
          File.mkfifo(fifo)
          clock = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
          beats = []
          beats_lock = Mutex.new
          heartbeat = Thread.new do
            loop do
              beats_lock.synchronize { beats << clock.call }
              sleep 0.02
            end
          end
          writer = fork do
            sleep 0.8
            File.write(fifo, "ok\n")
          end

          begin
            easy.url = "file://#{fifo}"
            multi.add(easy)

            started = clock.call
            multi.perform
            finished = clock.call

            expect(easy.response_body).to eq("ok\n")
            expect(finished - started).to be >= 0.4

            # The point is that the heartbeat ran while libcurl blocked, not
            # that it ran at a perfectly steady interval. A single delayed
            # heartbeat made this flaky on loaded CI runners.
            during = beats_lock.synchronize do
              beats.count { |beat| beat > started + 0.15 && beat < finished - 0.05 }
            end
            expect(during).to be > 0
          ensure
            heartbeat.kill
            heartbeat.join
            unless Process.waitpid(writer, Process::WNOHANG)
              Process.kill(:TERM, writer)
              Process.wait(writer)
            end
          end
        end
      end
    end
  end

  describe "#ongoing?" do
    context "when easy_handles" do
      before { multi.easy_handles << 1 }

      context "when running_count not greater 0" do
        before { multi.instance_variable_set(:@running_count, 0) }

        it "returns true" do
          expect(multi.method(:ongoing?).call).to be_truthy
        end
      end

      context "when running_count greater 0" do
        before { multi.instance_variable_set(:@running_count, 1) }

        it "returns true" do
          expect(multi.method(:ongoing?).call).to be_truthy
        end
      end
    end

    context "when no easy_handles" do
      context "when running_count not greater 0" do
        before { multi.instance_variable_set(:@running_count, 0) }

        it "returns false" do
          expect(multi.method(:ongoing?).call).to be_falsey
        end
      end

      context "when running_count is nil" do
        before do
          multi.instance_variable_set(:@running_count, nil)
        end

        it "returns false" do
          expect(multi.method(:ongoing?).call).to be_falsey
        end
      end

      context "when running_count greater 0" do
        before { multi.instance_variable_set(:@running_count, 1) }

        it "returns true" do
          expect(multi.method(:ongoing?).call).to be_truthy
        end
      end
    end
  end

  describe "#init_vars" do
    it "sets @timeout" do
      expect(multi.instance_variable_get(:@timeout)).to be_a(FFI::MemoryPointer)
    end

    it "sets @running_count_pointer" do
      expect(multi.instance_variable_get(:@running_count_pointer)).to be_a(FFI::MemoryPointer)
    end

    it "sets @msgs_left" do
      expect(multi.instance_variable_get(:@msgs_left)).to be_a(FFI::MemoryPointer)
    end

    it "does not allocate fd sets when curl_multi_poll is available" do
      skip "curl_multi_poll is unavailable" unless Ethon::Curl.respond_to?(:multi_poll)

      expect(multi.instance_variable_get(:@wait_strategy)).to eq(:poll)
      expect(multi.instance_variable_get(:@fd_read)).to be_nil
      expect(multi.instance_variable_get(:@fd_write)).to be_nil
      expect(multi.instance_variable_get(:@fd_excep)).to be_nil
      expect(multi.instance_variable_get(:@max_fd)).to be_nil
    end

    context "when only curl_multi_wait is available" do
      before do
        allow(Ethon::Curl).to receive(:respond_to?).and_call_original
        allow(Ethon::Curl).to receive(:respond_to?).with(:multi_poll).and_return(false)
        allow(Ethon::Curl).to receive(:respond_to?).with(:multi_wait).and_return(true)
        multi.init_vars
      end

      it "uses wait without allocating fd sets" do
        expect(multi.instance_variable_get(:@wait_strategy)).to eq(:wait)
        expect(multi.instance_variable_get(:@fd_read)).to be_nil
      end
    end

    context "when neither poll nor wait is available" do
      before do
        allow(Ethon::Curl).to receive(:respond_to?).and_call_original
        allow(Ethon::Curl).to receive(:respond_to?).with(:multi_poll).and_return(false)
        allow(Ethon::Curl).to receive(:respond_to?).with(:multi_wait).and_return(false)
        multi.init_vars
      end

      it "uses select and allocates the fd sets" do
        expect(multi.instance_variable_get(:@wait_strategy)).to eq(:select)
        expect(multi.instance_variable_get(:@timeval)).to be_a(Ethon::Curl::Timeval)
        expect(multi.instance_variable_get(:@fd_read)).to be_a(Ethon::Curl::FDSet)
        expect(multi.instance_variable_get(:@fd_write)).to be_a(Ethon::Curl::FDSet)
        expect(multi.instance_variable_get(:@fd_excep)).to be_a(Ethon::Curl::FDSet)
        expect(multi.instance_variable_get(:@max_fd)).to be_a(FFI::MemoryPointer)
      end
    end
  end

  describe "#reset_fds" do
    before do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_poll).and_return(false)
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_wait).and_return(false)
      multi.init_vars
    end

    after { multi.method(:reset_fds).call }

    it "resets @fd_read" do
      expect(multi.instance_variable_get(:@fd_read)).to receive(:clear)
    end

    it "resets @fd_write" do
      expect(multi.instance_variable_get(:@fd_write)).to receive(:clear)
    end

    it "resets @fd_excep" do
      expect(multi.instance_variable_get(:@fd_excep)).to receive(:clear)
    end
  end

  describe "#check" do
    let(:message) { FFI::MemoryPointer.new(Ethon::Curl::Msg) }
    let(:msg) { Ethon::Curl::Msg.new(message) }
    let(:null) { FFI::Pointer::NULL }

    before do
      easy.url = "http://127.0.0.1:3001/"
      multi.add(easy)
      allow(Ethon::Curl).to receive(:multi_info_read).and_return(msg, null)
    end

    after do
      multi.delete(easy) if multi.easy_handles.include?(easy)
    end

    it "ignores messages that are not done" do
      msg[:code] = :none

      expect(easy).not_to receive(:complete)
      multi.send(:check)

      expect(multi.easy_handles).to include(easy)
    end

    it "completes and removes done handles" do
      completed = false
      msg[:code] = :done
      msg[:easy_handle] = easy.handle
      msg[:data][:code] = :couldnt_connect
      easy.on_complete { completed = true }

      multi.send(:check)

      expect(easy.return_code).to eq(:couldnt_connect)
      expect(completed).to be(true)
      expect(multi.easy_handles).not_to include(easy)
    end

    it "ignores completion messages for handles it does not track" do
      msg[:code] = :done
      msg[:easy_handle] = FFI::Pointer.new(1)
      msg[:data][:code] = :ok

      expect(easy).not_to receive(:complete)
      expect { multi.send(:check) }.not_to raise_error
    end

    it "raises callback errors after completing and removing the handle" do
      error = RuntimeError.new("callback failed")
      msg[:code] = :done
      msg[:easy_handle] = easy.handle
      msg[:data][:code] = :ok
      easy.instance_variable_set(:@callback_error, error)

      expect { multi.send(:check) }.to raise_error(error)
      expect(multi.easy_handles).not_to include(easy)
    end

    it "reuses the message pointer" do
      pointer = multi.instance_variable_get(:@msgs_left)

      expect(Ethon::Curl).to receive(:multi_info_read) do |_, msgs|
        expect(msgs).to be(pointer)
        FFI::Pointer::NULL
      end

      multi.send(:check)
    end
  end

  describe "#socket_action" do
    let(:multi) { Ethon::Multi.new(:execution_mode => :socket_action) }

    before do
      allow(Ethon::Curl).to receive(:multi_socket_action) do |handle, fd, readiness, running|
        running.write_int(0)
        :ok
      end
    end

    it "accepts an integer file descriptor" do
      expect(Ethon::Curl).to receive(:multi_socket_action).
        with(multi.handle, 42, 0, anything) do |_handle, _fd, _readiness, running|
          running.write_int(0)
          :ok
        end

      expect(multi.socket_action(42)).to eq(:ok)
    end

    it "accepts an IO object" do
      io = double(:fileno => 7)

      expect(Ethon::Curl).to receive(:multi_socket_action).
        with(multi.handle, 7, 0, anything) do |_handle, _fd, _readiness, running|
          running.write_int(0)
          :ok
        end

      multi.socket_action(io)
    end
  end

  describe "#run" do
    it "checks for completed requests" do
      expect(multi).to receive(:trigger).and_return(:ok)
      expect(multi).to receive(:check)

      multi.send(:run)
    end

    it "retries while libcurl requests another perform" do
      expect(multi).to receive(:trigger).twice.and_return(:call_multi_perform, :ok)
      expect(multi).to receive(:check).once

      multi.send(:run)
    end

    it "raises on fatal errors" do
      expect(multi).to receive(:trigger).and_return(:internal_error)
      expect(multi).not_to receive(:check)

      expect { multi.send(:run) }.to raise_error(
        Ethon::Errors::MultiPerform,
        /internal_error/
      )
    end

    it "reuses the running count pointer" do
      pointer = multi.instance_variable_get(:@running_count_pointer)

      expect(Ethon::Curl).to receive(:multi_perform) do |_, running|
        expect(running).to be(pointer)
        running.write_int(0)
        :ok
      end

      multi.send(:run)
    end
  end

  describe "#trigger" do
    it "calls multi perform" do
      expect(Ethon::Curl).to receive(:multi_perform)
      multi.send(:trigger, pointer)
    end

    it "sets running count" do
      multi.instance_variable_set(:@running_count, nil)
      multi.send(:trigger, pointer)
      expect(multi.instance_variable_get(:@running_count)).to_not be_nil
    end

    it "returns multi perform code" do
      expect(Ethon::Curl).to receive(:multi_perform).and_return(:ok)
      expect(multi.send(:trigger, pointer)).to eq(:ok)
    end
  end
end
