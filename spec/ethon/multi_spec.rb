# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Multi do
  describe ".new" do
    it "inits curl" do
      expect(Ethon::Curl).to receive(:init)
      Ethon::Multi.new
    end

    context "with default options" do
      it "allows running #perform with the default execution_mode" do
        Ethon::Multi.new.perform
      end

      it "refuses to run #socket_action" do
        expect { Ethon::Multi.new.socket_action }.to raise_error(ArgumentError)
      end
    end

    context "when options not empty" do
      context "when pipelining is set" do
        let(:options) { { :pipelining => true } }

        it "sets pipelining" do
          expect_any_instance_of(Ethon::Multi).to receive(:pipelining=).with(true)
          Ethon::Multi.new(options)
        end

        it "accepts true" do
          expect { Ethon::Multi.new(:pipelining => true) }.not_to raise_error
        end

        it "accepts false" do
          expect { Ethon::Multi.new(:pipelining => false) }.not_to raise_error
        end
      end

      context "when execution_mode option is :socket_action" do
        let(:options) { { :execution_mode => :socket_action } }
        let(:multi) { Ethon::Multi.new(options) }

        it "refuses to run #perform" do
          expect { multi.perform }.to raise_error(ArgumentError)
        end

        it "allows running #socket_action" do
          multi.socket_action
        end
      end

      it "does not mutate the caller's options" do
        options = { :execution_mode => :socket_action, :maxconnects => 2 }

        Ethon::Multi.new(options)

        expect(options).to eq(:execution_mode => :socket_action, :maxconnects => 2)
      end

      it "raises for unknown options" do
        expect { Ethon::Multi.new(:bogus => 1) }.
          to raise_error(Ethon::Errors::InvalidOption)
      end

      it "raises for an unknown execution mode" do
        expect { Ethon::Multi.new(:execution_mode => :bogus) }.
          to raise_error(ArgumentError, /Unknown execution mode/)
      end
    end
  end

  describe "#dup" do
    let(:multi) { Ethon::Multi.new }

    it "refuses to duplicate a multi" do
      expect { multi.dup }.to raise_error(TypeError, /cannot duplicate/)
      expect { multi.clone }.to raise_error(TypeError, /cannot duplicate/)
    end

    it "refuses even after the handle and stack are materialized" do
      multi.easy_handles
      multi.handle

      expect { multi.dup }.to raise_error(TypeError, /cannot duplicate/)
    end

    it "leaves the original usable" do
      multi.easy_handles
      expect { multi.dup }.to raise_error(TypeError)

      easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
      multi.add(easy)
      multi.perform

      expect(easy.return_code).to eq(:ok)
    ensure
      multi.cleanup unless multi.instance_variable_get(:@cleaned_up)
    end
  end

  describe "#prepare" do
    it "warns and does nothing" do
      expect(Ethon.logger).to receive(:warn).with(/no longer necessary/)

      Ethon::Multi.new.prepare
    end
  end

  describe "#socket_action" do
    let(:options) { { :execution_mode => :socket_action } }
    let(:select_state) { { :readers => [], :writers => [], :timeout => 0 } }
    let(:multi) {
      multi = Ethon::Multi.new(options)
      multi.timerfunction = proc do |handle, timeout_ms, userp|
        timeout_ms = nil if timeout_ms == -1
        select_state[:timeout] = timeout_ms
        :ok
      end
      multi.socketfunction = proc do |handle, sock, what, userp, socketp|
        case what
        when :remove
          select_state[:readers].delete(sock)
          select_state[:writers].delete(sock)
        when :in
          select_state[:readers].push(sock) unless select_state[:readers].include? sock
          select_state[:writers].delete(sock)
        when :out
          select_state[:readers].delete(sock)
          select_state[:writers].push(sock) unless select_state[:writers].include? sock
        when :inout
          select_state[:readers].push(sock) unless select_state[:readers].include? sock
          select_state[:writers].push(sock) unless select_state[:writers].include? sock
        else
          raise ArgumentError, "invalid value for 'what' in socketfunction callback"
        end
        :ok
      end
      multi
    }

    def fds_to_ios(fds)
      fds.map do |fd|
        IO.for_fd(fd).tap { |io| io.autoclose = false }
      end
    end

    def perform_socket_action_until_complete
      GC.start
      multi.socket_action # start things off

      while multi.ongoing?
        readers, writers, _ = IO.select(
          fds_to_ios(select_state[:readers]),
          fds_to_ios(select_state[:writers]),
          [],
          select_state[:timeout]
        )

        to_notify = Hash.new { |hash, key| hash[key] = [] }
        unless readers.nil?
          readers.each do |reader|
            to_notify[reader] << :in
          end
        end
        unless writers.nil?
          writers.each do |writer|
            to_notify[writer] << :out
          end
        end

        to_notify.each do |io, readiness|
          multi.socket_action(io, readiness)
        end

        # if we didn't have anything to notify, then we timed out
        multi.socket_action if to_notify.empty?
      end
    ensure
      multi.easy_handles.dup.each do |h|
        multi.delete(h)
      end
    end

    it "supports an end-to-end request", :unless => Ethon::Curl.windows? do
      easy = Ethon::Easy.new
      easy.url = "http://127.0.0.1:3001/"
      multi.add(easy)

      perform_socket_action_until_complete

      expect(multi.ongoing?).to eq(false)
    end

    it "supports multiple concurrent requests", :unless => Ethon::Curl.windows? do
      handles = []
      10.times do
        easy = Ethon::Easy.new
        easy.url = "http://127.0.0.1:3001/?delay=0.2"
        multi.add(easy)
        handles << easy
      end

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      perform_socket_action_until_complete
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      # these should have happened concurrently
      expect(duration).to be < 1.0
      expect(multi.ongoing?).to eq(false)

      handles.each do |handle|
        expect(handle.response_code).to eq(200)
      end
    end
  end

  describe "#perform" do
    it "runs several delayed requests concurrently" do
      multi = Ethon::Multi.new
      handles = 10.times.map do
        easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/?delay=0.2")
        multi.add(easy)
        easy
      end

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      multi.perform
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      expect(duration).to be < 1.0
      expect(multi.ongoing?).to eq(false)
      handles.each do |handle|
        expect(handle.response_code).to eq(200)
      end
    ensure
      multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
    end
  end
end
