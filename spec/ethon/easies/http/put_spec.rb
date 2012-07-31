require 'spec_helper'

describe Ethon::Easies::Http::Put do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:put) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { put.setup(easy) }

    context "when nothing" do
      it "sets url" do
        expect(easy.url).to eq(url)
      end

      it "sets upload" do
        expect(easy.upload).to be_true
      end

      it "sets infilesize" do
        expect(easy.infilesize).to be_zero
      end

      context "when requesting" do
        it "makes a put request" do
          easy.prepare
          easy.perform
          expect(easy.response_body).to include('"REQUEST_METHOD":"PUT"')
        end
      end
    end

    context "when params" do
      let(:params) { {:a => "1&"} }

      it "attaches escaped to url" do
        expect(easy.url).to eq("#{url}?a=1%26")
      end

      it "sets upload" do
        expect(easy.upload).to be_true
      end

      it "sets infilesize" do
        expect(easy.infilesize).to be_zero
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "makes a put request" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"PUT"')
        end
      end
    end

    context "when body" do
      let(:form) { {:a => "1&b=2"} }

      it "sets infilesize" do
        expect(easy.infilesize).to_not be_zero
      end

      it "sets readfunction" do
        expect(easy.readfunction).to_not be_nil
      end

      it "sets upload" do
        expect(easy.upload).to be_true
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "makes a put request" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"PUT"')
        end

        it "submits a body" do
          expect(easy.response_body).to include('"body":"a=1%26b%3D2"')
        end
      end
    end

    context "when params and body"
  end
end
