# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::Slist do
  describe ".build" do
    it "returns nil without lines" do
      expect(described_class.build([])).to be_nil
    end

    it "builds a list from lines" do
      list = described_class.build(["X-First: 1", "X-Second: 2"])

      expect(described_class.new(list).to_a).
        to eq(["X-First: 1", "X-Second: 2"])
    end

    it "frees the previous list and raises when an append fails" do
      first = FFI::MemoryPointer.new(:pointer)
      allow(Ethon::Curl).to receive(:slist_append).and_return(first, FFI::Pointer::NULL)
      expect(Ethon::Curl).to receive(:slist_free_all).with(first)

      expect { described_class.build(["one", "two"]) }.
        to raise_error(NoMemoryError, "curl_slist_append failed")
    end
  end
end

describe Ethon::Curl::FDSet do
  it "uses a word-aligned fd_set size" do
    skip "Windows uses a fixed fd_array" if Ethon::Curl.windows?

    expect(described_class::FD_SETSIZE % FFI::Type::LONG.size).to eq(0)
  end
end

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
