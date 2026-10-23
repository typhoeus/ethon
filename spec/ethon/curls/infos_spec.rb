# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curls::Infos do
  let(:handle) { FFI::Pointer::NULL }

  describe ".get_info_string" do
    before { allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok) }

    it "returns the string" do
      string = FFI::MemoryPointer.from_string("value")
      result = FFI::MemoryPointer.new(:pointer)
      result.write_pointer(string)
      allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(result)

      expect(Ethon::Curl.get_info_string(:effective_url, handle)).to eq("value")
    end

    it "returns nil for a null pointer" do
      result = FFI::MemoryPointer.new(:pointer)
      result.write_pointer(FFI::Pointer::NULL)
      allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(result)

      expect(Ethon::Curl.get_info_string(:effective_url, handle)).to be_nil
    end

    it "returns nil when getinfo fails" do
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:unknown_option)

      expect(Ethon::Curl.get_info_string(:effective_url, handle)).to be_nil
    end
  end

  describe ".get_info_long" do
    it "returns the value" do
      result = FFI::MemoryPointer.new(:long)
      result.write_long(200)
      allow(FFI::MemoryPointer).to receive(:new).with(:long).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)

      expect(Ethon::Curl.get_info_long(:response_code, handle)).to eq(200)
    end

    it "returns nil when getinfo fails" do
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:unknown_option)

      expect(Ethon::Curl.get_info_long(:response_code, handle)).to be_nil
    end
  end

  describe ".get_info_double" do
    it "returns the value" do
      result = FFI::MemoryPointer.new(:double)
      result.write_double(1.5)
      allow(FFI::MemoryPointer).to receive(:new).with(:double).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)

      expect(Ethon::Curl.get_info_double(:total_time, handle)).to eq(1.5)
    end

    it "returns nil when getinfo fails" do
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:unknown_option)

      expect(Ethon::Curl.get_info_double(:total_time, handle)).to be_nil
    end
  end

  describe ".get_info_certinfo" do
    it "returns an empty array for a null pointer" do
      result = FFI::MemoryPointer.new(:pointer)
      result.write_pointer(FFI::Pointer::NULL)
      allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)

      expect(Ethon::Curl.get_info_certinfo(:certinfo, handle)).to eq([])
    end

    it "returns nil when getinfo fails" do
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:unknown_option)

      expect(Ethon::Curl.get_info_certinfo(:certinfo, handle)).to be_nil
    end
  end
end
