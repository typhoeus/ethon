# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Multi do
  let(:multi) { Ethon::Multi.new }

  describe "#wait" do
    it "returns the number of ready descriptors" do
      expect(Ethon::Curl).to receive(:multi_wait) do |handle, fds, nfds, timeout, numfds|
        expect(handle).to eq(multi.handle)
        expect(fds.null?).to be(true)
        expect(nfds).to eq(0)
        expect(timeout).to eq(100)
        numfds.write_int(2)
        :ok
      end

      expect(multi.wait(100)).to eq(2)
    end

    it "raises on errors" do
      allow(Ethon::Curl).to receive(:multi_wait).and_return(:bad_handle)

      expect { multi.wait }.to raise_error(Ethon::Errors::MultiWait, /bad_handle/)
    end

    it "raises when curl_multi_wait is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_wait).and_return(false)

      expect { multi.wait }.to raise_error(NotImplementedError, /curl_multi_wait/)
    end
  end

  describe "#poll" do
    it "returns the number of ready descriptors" do
      expect(Ethon::Curl).to receive(:multi_poll) do |handle, fds, nfds, timeout, numfds|
        expect(handle).to eq(multi.handle)
        expect(fds.null?).to be(true)
        expect(nfds).to eq(0)
        expect(timeout).to eq(100)
        numfds.write_int(1)
        :ok
      end

      expect(multi.poll(100)).to eq(1)
    end

    it "raises on errors" do
      allow(Ethon::Curl).to receive(:multi_poll).and_return(:internal_error)

      expect { multi.poll }.to raise_error(Ethon::Errors::MultiPoll, /internal_error/)
    end

    it "raises when curl_multi_poll is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_poll).and_return(false)

      expect { multi.poll }.to raise_error(NotImplementedError, /curl_multi_poll/)
    end
  end

  describe "#wakeup" do
    it "wakes up the multi" do
      expect(Ethon::Curl).to receive(:multi_wakeup).with(multi.handle).and_return(:ok)

      expect(multi.wakeup).to eq(:ok)
    end

    it "raises on errors" do
      allow(Ethon::Curl).to receive(:multi_wakeup).and_return(:wakeup_failure)

      expect { multi.wakeup }.to raise_error(Ethon::Errors::MultiWakeup, /wakeup_failure/)
    end

    it "raises when curl_multi_wakeup is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_wakeup).and_return(false)

      expect { multi.wakeup }.to raise_error(NotImplementedError, /curl_multi_wakeup/)
    end
  end
end
