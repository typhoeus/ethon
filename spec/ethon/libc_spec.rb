# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Libc do
  describe "#sysconf(:open_max)", :if => !Ethon::Curl.windows? do
    it "returns an integer" do
      expect(Ethon::Libc.sysconf(:open_max)).to be_a(Integer)
    end

    it "returns bigger zero", :if => !Ethon::Curl.windows? do
      expect(Ethon::Libc.sysconf(:open_max)).to_not be_zero
    end
  end
end
