# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy do
  let(:easy) { Ethon::Easy.new }

  describe "#pause" do
    it "pauses the requested directions" do
      expect(Ethon::Curl).to receive(:easy_pause).
        with(easy.handle, Ethon::Curl::PAUSE_RECV).and_return(:ok)

      expect(easy.pause(Ethon::Curl::PAUSE_RECV)).to eq(:ok)
    end

    it "continues by default" do
      expect(Ethon::Curl).to receive(:easy_pause).
        with(easy.handle, Ethon::Curl::PAUSE_CONT).and_return(:ok)

      easy.pause
    end

    it "raises when curl_easy_pause is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:easy_pause).and_return(false)

      expect { easy.pause }.to raise_error(NotImplementedError, /curl_easy_pause/)
    end
  end

  describe "#upkeep" do
    it "calls curl_easy_upkeep" do
      expect(Ethon::Curl).to receive(:easy_upkeep).with(easy.handle).and_return(:ok)

      expect(easy.upkeep).to eq(:ok)
    end

    it "raises when curl_easy_upkeep is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:easy_upkeep).and_return(false)

      expect { easy.upkeep }.to raise_error(NotImplementedError, /curl_easy_upkeep/)
    end
  end
end
