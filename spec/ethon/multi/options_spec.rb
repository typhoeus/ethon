# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Multi::Options do
  let(:multi) { Ethon::Multi.new }

  [
    :maxconnects, :pipelining, :socketdata, :socketfunction,
    :timerdata, :timerfunction, :max_total_connections
  ].each do |name|
    describe "#{name}=" do
      it "responds_to" do
        expect(multi).to respond_to("#{name}=")
      end

      it "sets option" do
        expect(Ethon::Curl).to receive(:set_option).with(name, anything, anything, anything)
        multi.method("#{name}=").call(1)
      end
    end
  end

  context "socket_action mode" do
    let(:multi) { Ethon::Multi.new(execution_mode: :socket_action) }

    describe "#socketfunction callbacks" do
      it "allows multi_code return values" do
        calls = []
        multi.socketfunction = proc do |handle, sock, what, userp, socketp|
          calls << what
          :ok
        end

        easy = Ethon::Easy.new
        easy.url = "http://localhost:3001/?delay=1"
        multi.add(easy)
        expect(calls).to eq([])
        multi.socket_action
        expect(calls).to eq([:in])
        multi.delete(easy)
        expect(calls).to eq([:in, :remove])
      end

      it "allows integer return values (compatibility)" do
        called = false
        multi.socketfunction = proc do |handle, sock, what, userp, socketp|
          called = true
          0
        end

        easy = Ethon::Easy.new
        easy.url = "http://localhost:3001/?delay=1"
        multi.add(easy)
        multi.socket_action
        multi.delete(easy)

        expect(called).to be_truthy
      end

      it "errors on invalid return codes" do
        called = false
        multi.socketfunction = proc do |handle, sock, what, userp, socketp|
          called = true
          "hi"
        end

        easy = Ethon::Easy.new
        easy.url = "http://localhost:3001/?delay=1"
        multi.add(easy)
        expect { multi.socket_action }.to raise_error(ArgumentError)
        expect { multi.delete(easy) }.to raise_error(ArgumentError)
      end
    end

    describe "#timerfunction callbacks" do
      it "allows multi_code return values" do
        calls = []
        multi.timerfunction = proc do |handle, timeout_ms, userp|
          calls << timeout_ms
          :ok
        end

        easy = Ethon::Easy.new
        easy.url = "http://localhost:3001/?delay=1"
        multi.add(easy)
        expect(calls).to eq([0]) # adds an immediate timeout

        multi.socket_action
        expect(calls).to eq([0, 1]) # nothing was ready, so waits 1ms

        multi.delete(easy)
        expect(calls).to eq([0, 1, -1]) # cancels the timer
      end

      it "allows integer return values (compatibility)" do
        called = false
        multi.timerfunction = proc do |handle, timeout_ms, userp|
          called = true
          0
        end

        easy = Ethon::Easy.new
        easy.url = "http://localhost:3001/?delay=1"
        multi.add(easy)
        multi.socket_action
        multi.delete(easy)

        expect(called).to be_truthy
      end

      it "errors on invalid return codes" do
        called = false
        multi.timerfunction = proc do |handle, timeout_ms, userp|
          called = true
          "hi"
        end

        easy = Ethon::Easy.new
        easy.url = "http://localhost:3001/?delay=1"
        expect { multi.add(easy) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#value_for" do
    context "when option in bool" do
      context "when value true" do
        let(:value) { true }

        it "returns 1" do
          expect(multi.method(:value_for).call(value, :bool)).to eq(1)
        end
      end

      context "when value false" do
        let(:value) { false }

        it "returns 0" do
          expect(multi.method(:value_for).call(value, :bool)).to eq(0)
        end
      end
    end


    context "when value in int" do
      let(:value) { "2" }

      it "returns value casted to int" do
        expect(multi.method(:value_for).call(value, :int)).to eq(2)
      end
    end

    context "when value in unspecific_options" do
      context "when value a string" do
        let(:value) { "www.example.\0com" }

        it "returns zero byte escaped string" do
          expect(multi.method(:value_for).call(value, nil)).to eq("www.example.\\0com")
        end
      end

      context "when value not a string" do
        let(:value) { 1 }

        it "returns value" do
          expect(multi.method(:value_for).call(value, nil)).to eq(1)
        end
      end
    end
  end
end
