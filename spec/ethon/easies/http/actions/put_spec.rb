require 'spec_helper'

describe Ethon::Easies::Http::Actions::Put do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:put) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { put.setup(easy) }

    context "when nothing" do
      it "sets url" do
        easy.url.should eq(url)
      end

      it "sets upload" do
        easy.upload.should be_true
      end

      it "sets infilesize" do
        easy.infilesize.should be_zero
      end

      context "when requesting" do
        it "makes a put request" do
          easy.prepare
          easy.perform
          easy.response_body.should include('"REQUEST_METHOD":"PUT"')
        end
      end
    end

    context "when params" do
      let(:params) { {:a => "1&"} }

      it "attaches escaped to url" do
        easy.url.should eq("#{url}?a=1%26")
      end

      it "sets upload" do
        easy.upload.should be_true
      end

      it "sets infilesize" do
        easy.infilesize.should be_zero
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "makes a put request" do
          easy.response_body.should include('"REQUEST_METHOD":"PUT"')
        end
      end
    end

    context "when body" do
      let(:form) { {:a => "1"} }

      it "sets infilesize" do
        easy.infilesize.should_not be_zero
      end

      it "sets readfunction" do
        easy.readfunction.should_not be_nil
      end

      it "sets upload" do
        easy.upload.should be_true
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "makes a put request" do
          easy.response_body.should include('"REQUEST_METHOD":"PUT"')
        end

        it "submits a body" do
          easy.response_body.should include("a=1")
        end
      end
    end

    context "when params and body"
  end
end
