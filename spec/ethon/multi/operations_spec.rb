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

    it "rejects a handle inherited across a fork" do
      multi.handle
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          multi.perform
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

  describe "#running_count" do
    context "when hydra has no easy" do
      it "returns nil" do
        expect(multi.send(:running_count)).to be_nil
      end
    end

    context "when hydra has easy" do
      before do
        easy.url = "http://localhost:3001/"
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
        easy.url = "http://localhost:3001/"
        another_easy.url = "http://localhost:3001/"
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

    context "when code ok" do
      before { expect(Ethon::Curl).to receive(:multi_fdset).and_return(:ok) }

      it "doesn't raise" do
        expect{ multi.method(:set_fds).call(timeout) }.to_not raise_error
      end

      context "when max_fd -1" do
        let(:max_fd) { -1 }

        before do
          multi.instance_variable_set(:@max_fd, double(:read_int => max_fd))
          expect(multi).to receive(:sleep).with(0.001)
        end

        it "waits 100ms" do
          multi.method(:set_fds).call(timeout)
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
        easy.url = "http://localhost:3001/"
        multi.add(easy)
      end

      it "requests" do
        multi.perform
      end

      it "sets easy" do
        multi.perform
        expect(easy.response_code).to eq(200)
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

      it "streams the response to a caller-owned IO" do
        io = StringIO.new
        easy.file = io

        multi.perform

        expect(io.string).to include('"REQUEST_METHOD":"GET"')
        expect(io).not_to be_closed
      end
    end

    context "when four easy handles" do
      let(:easies) do
        ary = []
        4.times do
          ary << another_easy = Ethon::Easy.new
          another_easy.url = "http://localhost:3001/"
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
          last = clock.call
          max_gap = 0.0
          heartbeat = Thread.new do
            loop do
              now = clock.call
              max_gap = [max_gap, now - last].max
              last = now
              sleep 0.02
            end
          end
          writer = fork do
            sleep 1
            File.write(fifo, "ok\n")
          end

          begin
            easy.url = "file://#{fifo}"
            multi.add(easy)
            multi.perform

            expect(easy.response_body).to eq("ok\n")
            expect(max_gap).to be < 0.5
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

    it "sets @timeval" do
      expect(multi.instance_variable_get(:@timeval)).to be_a(Ethon::Curl::Timeval)
    end

    it "sets @fd_read" do
      expect(multi.instance_variable_get(:@fd_read)).to be_a(Ethon::Curl::FDSet)
    end

    it "sets @fd_write" do
      expect(multi.instance_variable_get(:@fd_write)).to be_a(Ethon::Curl::FDSet)
    end

    it "sets @fd_excep" do
      expect(multi.instance_variable_get(:@fd_excep)).to be_a(Ethon::Curl::FDSet)
    end

    it "sets @max_fd" do
      expect(multi.instance_variable_get(:@max_fd)).to be_a(FFI::MemoryPointer)
    end
  end

  describe "#reset_fds" do
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
    it { skip("untested") }
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
