# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::EasyHandle do
  describe ".release" do
    let(:pointer) { double(:address => 4242) }

    after { described_class.owners.delete(pointer.address) }

    it "frees a pointer owned by the current process" do
      described_class.owners[pointer.address] = Process.pid

      expect(described_class).to receive(:native_release).with(pointer)

      described_class.release(pointer)
    end

    it "does not free a pointer inherited from another process" do
      described_class.owners[pointer.address] = Process.pid + 1

      expect(described_class).not_to receive(:native_release)

      described_class.release(pointer)
    end

    it "does not free an unknown pointer" do
      expect(described_class).not_to receive(:native_release)

      described_class.release(pointer)
    end

    it "still frees when the owners mutex cannot be used" do
      described_class.owners[pointer.address] = Process.pid
      allow(described_class::OWNERS_MUTEX).to receive(:synchronize).and_raise(ThreadError)

      expect(described_class).to receive(:native_release).with(pointer)

      described_class.release(pointer)
    end

    it "still frees when a signal interrupts the finalizer" do
      described_class.owners[pointer.address] = Process.pid
      allow(described_class::OWNERS_MUTEX).to receive(:synchronize).and_raise(SignalException.new("TERM"))

      expect(described_class).to receive(:native_release).with(pointer)

      described_class.release(pointer)
    end
  end
end
