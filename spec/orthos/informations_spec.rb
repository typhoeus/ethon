require 'spec_helper'

describe Orthos::Informations do
  let(:easy) { Orthos::Easy.new }

  before do
    easy.url = "http://localhost:3001"
    easy.prepare
    easy.perform
  end

  describe "#auth_methods" do
    it "returns" do
      easy.auth_methods.should be
    end
  end

  describe "#total_time_taken" do
    it "returns float" do
      easy.total_time_taken.should be_a(Float)
    end
  end

  describe "#start_transfer_time" do
    it "returns float" do
      easy.start_transfer_time.should be_a(Float)
    end
  end

  describe "#app_connect_time" do
    it "returns float" do
      easy.app_connect_time.should be_a(Float)
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

  describe "#name_lookup_time" do
    it "returns float" do
      easy.name_lookup_time.should be_a(Float)
    end
  end

  describe "#effective_url" do
    it "returns url" do
      easy.effective_url.should eq("http://localhost:3001")
    end
  end

  describe "#primary_ip" do
    it "returns localhost" do
      easy.primary_ip.should eq('127.0.0.1')
    end
  end

  describe "#response_code" do
    it "returns 200" do
      easy.response_code.should eq(200)
    end
  end

  describe "#supports_zlib?" do
    it "returns true" do
      easy.supports_zlib?.should be_true
    end
  end
end
