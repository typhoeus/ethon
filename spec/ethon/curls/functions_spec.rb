# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl do
  describe "transfer function bindings" do
    [:easy_unescape, :easy_pause, :easy_send, :easy_recv, :multi_wait].each do |name|
      it "attaches #{name}" do
        expect(described_class).to respond_to(name)
      end
    end

    [:easy_upkeep, :multi_poll, :multi_wakeup].each do |name|
      it "attaches #{name} when the loaded libcurl supports it" do
        skip "#{name} unavailable" unless described_class.respond_to?(name)

        expect(described_class).to respond_to(name)
      end
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
end
