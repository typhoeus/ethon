# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl do
  describe "optional function attachment" do
    it "ignores functions that are not exported by libcurl" do
      result = Ethon::Curls::Optional.attach(
        described_class, :ethon_missing_function, :curl_ethon_missing, [], :void
      )

      expect(result).to be_nil
      expect(described_class).not_to respond_to(:ethon_missing_function)
    end

  end

  describe "pause constants" do
    it "maps CURLPAUSE_* values" do
      expect(described_class::PAUSE_RECV).to eq(1)
      expect(described_class::PAUSE_SEND).to eq(4)
      expect(described_class::PAUSE_ALL).to eq(5)
      expect(described_class::PAUSE_CONT).to eq(0)
    end
  end

  describe "wait constants" do
    it "maps CURL_WAIT_* values" do
      expect(described_class::WAIT_POLLIN).to eq(0x0001)
      expect(described_class::WAIT_POLLPRI).to eq(0x0002)
      expect(described_class::WAIT_POLLOUT).to eq(0x0004)
    end
  end

  describe ".select" do
    it "releases the GVL while waiting" do
      skip "libc select is not used on Windows" if described_class.windows?

      timeout = described_class::Timeval.new
      timeout[:sec] = 0
      timeout[:usec] = 500_000

      counter = 0
      stop = false
      started = Queue.new
      worker = Thread.new do
        started << true
        sleep 0.02
        counter += 1 until stop
      end
      # Wait for the thread before entering select, so a delayed thread start
      # cannot be mistaken for a held GVL.
      started.pop

      described_class.select(0, nil, nil, nil, timeout)
      ran_during_select = counter > 0
      stop = true
      worker.join

      expect(ran_during_select).to be(true)
    end
  end
end
