require 'spec_helper'

describe Ethon::Easies::Http::Action do
  let(:easy) { Ethon::Easy.new }

  describe ".reset" do
    let(:action)  { Ethon::Easies::Http::Action }
    before { action.reset(easy) }

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
  end
end
