# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Multi do
  let(:multi) { Ethon::Multi.new }
  let(:easy) { Ethon::Easy.new }
  let(:pointer) { FFI::MemoryPointer.new(:int) }

  describe "#assign" do
    it "associates a pointer with a socket" do
      expect(Ethon::Curl).to receive(:multi_assign).
        with(multi.handle, 42, pointer).and_return(:ok)

      expect(multi.assign(42, pointer)).to eq(:ok)
    end

    it "accepts an IO" do
      io = double(:fileno => 7)

      expect(Ethon::Curl).to receive(:multi_assign).
        with(multi.handle, 7, pointer).and_return(:ok)

      multi.assign(io, pointer)
    end

    it "retains the pointer until it is cleared" do
      allow(Ethon::Curl).to receive(:multi_assign).and_return(:ok)

      multi.assign(42, pointer)

      expect(multi.instance_variable_get(:@assigned_sockets)[42]).to be(pointer)
    end

    it "clears the retained pointer with nil" do
      allow(Ethon::Curl).to receive(:multi_assign).and_return(:ok)
      multi.assign(42, pointer)

      multi.assign(42, nil)

      expect(multi.instance_variable_get(:@assigned_sockets)).to be_empty
    end

    it "rejects values that are not pointers" do
      expect { multi.assign(42, "not a pointer") }.
        to raise_error(Ethon::Errors::InvalidValue)
    end

    it "raises on errors" do
      allow(Ethon::Curl).to receive(:multi_assign).and_return(:bad_socket)

      expect { multi.assign(42, pointer) }.
        to raise_error(Ethon::Errors::MultiAssign, /bad_socket/)
    end
  end

  describe "#native_handles" do
    after do
      multi.delete(easy) if multi.easy_handles.include?(easy)
    end

    it "returns the attached easy handles" do
      multi.add(easy)

      expect(multi.native_handles.map(&:address)).to include(easy.handle.address)
    end

    it "returns an empty array without handles" do
      expect(multi.native_handles).to eq([])
    end

    it "raises when the function is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:multi_get_handles).and_return(false)

      expect { multi.native_handles }.
        to raise_error(NotImplementedError, /curl_multi_get_handles/)
    end
  end
end
