require 'spec_helper'

describe Ethon::Easies::Http::Action do
  let(:easy) { Ethon::Easy.new }

  describe ".reset" do
    let(:action)  { Ethon::Easies::Http::Action }
    before { action.reset(easy) }

    it "unsets http_get" do
      easy.http_get.should be_nil
    end

    it "unsets http_post" do
      easy.http_post.should be_nil
    end

    it "unsets upload" do
      easy.upload.should be_nil
    end

    it "unsets nobody" do
      easy.nobody.should be_nil
    end

    it "unsets custom_request" do
      easy.custom_request.should be_nil
    end
  end
end
