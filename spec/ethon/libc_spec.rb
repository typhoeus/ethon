# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Libc do
  describe ".open_max" do
    it "returns an integer" do
      expect(Ethon::Libc.open_max).to be_a(Integer)
    end

    it "returns bigger zero" do
      expect(Ethon::Libc.open_max).to be > 0
    end

    it "uses the process limit when sysconf is indeterminate" do
      allow(Etc).to receive(:sysconf).with(Etc::SC_OPEN_MAX).and_return(nil)
      allow(Process).to receive(:getrlimit).with(:NOFILE).and_return([1024, 1024])

      expect(Ethon::Libc.open_max).to eq(1024)
    end

    it "uses the process limit when sysconf is not implemented" do
      allow(Etc).to receive(:sysconf).and_raise(NotImplementedError)
      allow(Process).to receive(:getrlimit).with(:NOFILE).and_return([2048, 2048])

      expect(Ethon::Libc.open_max).to eq(2048)
    end

    it "uses the process limit when sysconf is not positive" do
      allow(Etc).to receive(:sysconf).with(Etc::SC_OPEN_MAX).and_return(0)
      allow(Process).to receive(:getrlimit).with(:NOFILE).and_return([4096, 4096])

      expect(Ethon::Libc.open_max).to eq(4096)
    end
  end

  describe ".fd_size" do
    let(:word) { FFI::Type::LONG.size }

    it "rounds the requested size up to the fd_set word size" do
      expect(Ethon::Libc.fd_size("100")).to eq(((100 + word - 1) / word) * word)
    end

    it "uses the detected limit by default" do
      allow(Ethon::Libc).to receive(:open_max).and_return(2_047)

      expect(Ethon::Libc.fd_size("")).to eq(((2_047 + word - 1) / word) * word)
    end

    it "rejects invalid sizes" do
      ["0", "-1", "nope"].each do |value|
        expect { Ethon::Libc.fd_size(value) }.
          to raise_error(ArgumentError, /ETHON_FD_SIZE/)
      end
    end
  end
end
