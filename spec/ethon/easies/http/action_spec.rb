require 'spec_helper'

describe Ethon::Easies::Http::Action do
  let(:easy) { Ethon::Easy.new }

  describe ".reset" do
    before do
      easy.url = "abc"
      easy.httpget = 1
      easy.httppost = 1
      easy.upload = 1
      easy.nobody = 1
      easy.customrequest = 1
      easy.postfieldsize = 1
      easy.copypostfields = 1
      easy.infilesize = 1
      described_class.reset(easy)
    end

    it "unsets url" do
      easy.url.should be_nil
    end

    it "unsets httpget" do
      easy.httpget.should be_nil
    end

    it "unsets httppost" do
      easy.httppost.should be_nil
    end

    it "unsets upload" do
      easy.upload.should be_nil
    end

    it "unsets nobody" do
      easy.nobody.should be_nil
    end

    it "unsets custom_request" do
      easy.customrequest.should be_nil
    end

    it "unsets postfieldsize" do
      easy.postfieldsize.should be_nil
    end

    it "unsets copypostfields" do
      easy.copypostfields.should be_nil
    end

    it "unsets infilesize" do
      easy.infilesize.should be_nil
    end
  end
end
