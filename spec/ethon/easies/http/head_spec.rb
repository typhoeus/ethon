require 'spec_helper'

describe Ethon::Easies::Http::Head do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:head) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { head.setup(easy) }

    context "when nothing" do
      it "sets nobody" do
        easy.nobody.should be
      end

      it "sets url" do
        easy.url.should eq(url)
      end
    end

    context "when params" do
      let(:params) { {:a => "1&b=2"} }

      it "sets nobody" do
        easy.nobody.should be
      end

      it "attaches escaped to url" do
        easy.url.should eq("#{url}?a=1%26b%3D2")
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "returns ok" do
          easy.return_code.should eq(:ok)
        end

        it "has no body" do
          easy.response_body.should be_empty
        end

        it "requests parameterized url" do
          easy.effective_url.should eq("http://localhost:3001/?a=1%26b%3D2")
        end
      end
    end
  end
end
