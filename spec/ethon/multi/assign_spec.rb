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

    it "rejects a nil socket descriptor" do
      expect(Ethon::Curl).not_to receive(:multi_assign)

      expect { multi.assign(nil, pointer) }.
        to raise_error(Ethon::Errors::InvalidValue, /assign/)
      expect(multi.instance_variable_get(:@assigned_sockets)).to be_nil
    end

    it "rejects a socket descriptor that is not an integer" do
      expect(Ethon::Curl).not_to receive(:multi_assign)

      expect { multi.assign("42", pointer) }.
        to raise_error(Ethon::Errors::InvalidValue, /assign/)
    end

    it "rejects an IO whose fileno is not an integer" do
      io = double(:fileno => "7")
      expect(Ethon::Curl).not_to receive(:multi_assign)

      expect { multi.assign(io, pointer) }.
        to raise_error(Ethon::Errors::InvalidValue, /assign/)
    end

    it "rejects a freed owned pointer" do
      list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))
      list.free

      expect(Ethon::Curl).not_to receive(:multi_assign)
      expect { multi.assign(42, list) }.
        to raise_error(Ethon::Errors::EthonError, /freed/)
      expect(multi.instance_variable_get(:@assigned_sockets)).to be_nil
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
      skip "curl_multi_get_handles is unavailable" unless Ethon::Curl.respond_to?(:multi_get_handles)

      multi.add(easy)

      expect(multi.native_handles.map(&:address)).to include(easy.handle.address)
    end

    it "returns an empty array without handles" do
      skip "curl_multi_get_handles is unavailable" unless Ethon::Curl.respond_to?(:multi_get_handles)

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
