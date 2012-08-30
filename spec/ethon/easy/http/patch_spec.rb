require 'spec_helper'

describe Ethon::Easy::Http::Patch do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:patch) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { patch.setup(easy) }

    it "sets customrequest" do
      expect(easy.customrequest).to eq("PATCH")
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

      it "is a patch request" do
        expect(easy.response_body).to include('"REQUEST_METHOD":"PATCH"')
      end

      it "requests parameterized url" do
        expect(easy.effective_url).to eq("http://localhost:3001/?a=1%26b%3D2")
      end
    end
  end
end
