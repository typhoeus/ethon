# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Multi do
  let(:multi) { Ethon::Multi.new }
  let(:pointer) { FFI::MemoryPointer.new(:int) }

  describe "#socketdata=" do
    it "accepts an FFI pointer" do
      expect(Ethon::Curl).to receive(:multi_setopt).
        with(multi.handle, anything, :pointer, pointer).and_return(:ok)

      multi.socketdata = pointer
    end

    it "rejects non-pointers" do
      expect { multi.socketdata = "not a pointer" }.
        to raise_error(Ethon::Errors::InvalidValue)
    end
  end

  describe "#timerdata=" do
    it "accepts an FFI pointer" do
      expect(Ethon::Curl).to receive(:multi_setopt).
        with(multi.handle, anything, :pointer, pointer).and_return(:ok)

      multi.timerdata = pointer
    end

    it "rejects non-pointers" do
      expect { multi.timerdata = "not a pointer" }.
        to raise_error(Ethon::Errors::InvalidValue)
    end
  end
end
