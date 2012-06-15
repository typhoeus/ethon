require 'spec_helper'

describe Ethon::Easies::Informations do
  let(:easy) { Ethon::Easy.new }

  before do
    easy.url = "http://localhost:3001"
    easy.prepare
    easy.perform
  end

  describe "#httpauth_avail" do
    it "returns" do
      easy.httpauth_avail.should be
    end
  end

  describe "#total_time" do
    it "returns float" do
      easy.total_time.should be_a(Float)
    end
  end

  describe "#starttransfer_time" do
    it "returns float" do
      easy.starttransfer_time.should be_a(Float)
    end
  end

  describe "#appconnect_time" do
    it "returns float" do
      easy.appconnect_time.should be_a(Float)
    end
  end

  describe "#pretransfer_time" do
    it "returns float" do
      easy.pretransfer_time.should be_a(Float)
    end
  end

  describe "#connect_time" do
    it "returns float" do
      easy.connect_time.should be_a(Float)
    end
  end

  describe "#namelookup_time" do
    it "returns float" do
      easy.namelookup_time.should be_a(Float)
    end
  end

  describe "#effective_url" do
    it "returns url" do
      easy.effective_url.should eq("http://localhost:3001")
    end
  end

  describe "#primary_ip" do
    it "returns localhost" do
      easy.primary_ip.should match(/::1|127\.0\.0\.1/)
    end
  end

  describe "#response_code" do
    it "returns 200" do
      easy.response_code.should eq(200)
    end
  end

  describe "#redirect_count" do
    it "returns 0" do
      easy.redirect_count.should eq(0)
    end
  end

  describe "#supports_zlib?" do
    it "returns true" do
      easy.supports_zlib?.should be_true
    end
  end
end
