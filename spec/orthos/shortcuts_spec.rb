require 'spec_helper'

describe Orthos::Shortcuts do
  let(:easy) { Orthos::Easy.new }

  describe "#action=" do
    context "when get" do
      before { easy.action = :get }

      it "sets http_get" do
        easy.http_get.should be
      end
    end

    context "when post" do
      before { easy.action = :post }

      it "sets http_post" do
        easy.http_post.should be
      end
    end

    context "when put" do
      before { easy.action = :put }

      it "sets upload" do
        easy.upload.should be
      end
    end

    context "when head" do
      before { easy.action = :head }

      it "sets nobody" do
        easy.nobody.should be
      end
    end

    context "when else" do
      before { easy.action = :delete }

      it "sets custom_request" do
        easy.custom_request.should eq("DELETE")
      end
    end
  end

  describe "#reset_action" do
    before { easy.reset_action }

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
