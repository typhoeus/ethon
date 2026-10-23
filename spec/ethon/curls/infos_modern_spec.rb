# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curls::Infos do
  let(:handle) { FFI::Pointer::NULL }

  describe ".get_info_off_t" do
    it "reads a 64-bit value" do
      result = FFI::MemoryPointer.new(:int64)
      result.write_int64(2**40)
      allow(FFI::MemoryPointer).to receive(:new).with(:int64).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)

      expect(Ethon::Curl.get_info_off_t(:total_time_t, handle)).to eq(2**40)
    end

    it "returns nil when getinfo fails" do
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:unknown_option)

      expect(Ethon::Curl.get_info_off_t(:total_time_t, handle)).to be_nil
    end
  end

  describe ".get_info_socket" do
    it "reads a native socket on Unix" do
      skip "Windows uses SOCKET" if Ethon::Curl.windows?
      result = FFI::MemoryPointer.new(:int)
      result.write_int(42)
      allow(FFI::MemoryPointer).to receive(:new).with(:int).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)

      expect(Ethon::Curl.get_info_socket(:activesocket, handle)).to eq(42)
    end

    it "returns nil when getinfo fails" do
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:unknown_option)

      expect(Ethon::Curl.get_info_socket(:activesocket, handle)).to be_nil
    end
  end

  describe ".get_info_ptr" do
    it "returns the pointer" do
      value = FFI::MemoryPointer.new(:int)
      result = FFI::MemoryPointer.new(:pointer)
      result.write_pointer(value)
      allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)

      expect(Ethon::Curl.get_info_ptr(:tls_ssl_ptr, handle)).to eq(value)
    end

    it "returns nil for NULL" do
      result = FFI::MemoryPointer.new(:pointer)
      result.write_pointer(FFI::Pointer::NULL)
      allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)

      expect(Ethon::Curl.get_info_ptr(:tls_ssl_ptr, handle)).to be_nil
    end
  end
end
