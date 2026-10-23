# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Informations do

  describe "#supports_asynch_dns?" do
    it "returns boolean" do
      expect([true, false].include? Ethon::Easy.supports_asynch_dns?).to be_truthy
    end
  end

  describe "#supports_zlib?" do
    it "returns boolean" do
      expect([true, false].include? Ethon::Easy.supports_zlib?).to be_truthy
    end
  end

  describe "#supports_timeout_ms?" do
    it "checks the libcurl version instead of async DNS support" do
      allow(Ethon::Curl).to receive(:version_info).
        and_return({ :version_num => 0x071001 })
      expect(Ethon::Easy.supports_timeout_ms?).to be(false)

      allow(Ethon::Curl).to receive(:version_info).
        and_return({ :version_num => 0x071002 })
      expect(Ethon::Easy.supports_timeout_ms?).to be(true)
    end
  end

end
