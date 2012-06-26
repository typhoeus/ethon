require 'spec_helper'

describe Ethon::Easies::Http::Get do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:get) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { get.setup(easy) }

    it "sets url" do
      easy.url.should eq(url)
    end

    context "when body" do
      let(:form) { { :a => 1 } }

      it "sets customrequest" do
        easy.customrequest.should eq("GET")
      end
    end

    context "when no body" do
      it "doesn't set customrequest" do
        easy.customrequest.should be_nil
      end
    end

    context "when requesting" do
      before do
        easy.prepare
        easy.perform
      end

      context "when params and no body" do
        let(:params) { {:a => "1&b=2"} }

        it "returns ok" do
          easy.return_code.should eq(:ok)
        end

        it "is a get request" do
          easy.response_body.should include('"REQUEST_METHOD":"GET"')
        end

        it "requests parameterized url" do
          easy.effective_url.should eq("http://localhost:3001/?a=1%26b%3D2")
        end
      end

      context "when params and body" do
        let(:params) { {:a => "1&b=2"} }
        let(:form) { {:b => "2"} }
        it "returns ok" do
          easy.return_code.should eq(:ok)
        end

        it "is a get request" do
          easy.response_body.should include('"REQUEST_METHOD":"GET"')
        end

        it "requests parameterized url" do
          easy.effective_url.should eq("http://localhost:3001/?a=1%26b%3D2")
        end
      end
    end
  end
end
