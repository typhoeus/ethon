require 'spec_helper'

describe Ethon::Easies::Http::Options do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:options) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { options.setup(easy) }

    it "sets customrequest" do
      expect(easy.customrequest).to eq("OPTIONS")
    end

    it "sets url" do
      expect(easy.url).to eq(url)
    end

    context "when requesting" do
      let(:params) { {:a => "1&b=2"} }

      before do
        easy.prepare
        easy.perform
      end

      it "returns ok" do
        expect(easy.return_code).to eq(:ok)
      end

      it "is a options request" do
        expect(easy.response_body).to include('"REQUEST_METHOD":"OPTIONS"')
      end

      it "requests parameterized url" do
        expect(easy.effective_url).to eq("http://localhost:3001/?a=1%26b%3D2")
      end
    end
  end
end
