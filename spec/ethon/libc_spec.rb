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
  end
end
