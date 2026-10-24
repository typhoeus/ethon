# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe Ethon::Easy::Http::Get do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:options) { {} }
  let(:get) { described_class.new(url, {:params => params, :body => form}.merge(options)) }

  describe "#setup" do
    it "sets url" do
      get.setup(easy)
      expect(easy.url).to eq(url)
    end

    context "when params is an empty string" do
      let(:params) { "" }
      let(:url) { "http://localhost:3001/?query=here" }

      it "leaves the url alone" do
        get.setup(easy)
        expect(easy.url).to eq(url)
      end
    end

    context "when url has a fragment" do
      let(:url) { "http://localhost:3001/#frag" }
      let(:params) { { :a => 1 } }

      it "puts params before the fragment" do
        get.setup(easy)
        expect(easy.url).to eq("http://localhost:3001/?a=1#frag")
      end
    end

    context "when url has a query and a fragment" do
      let(:url) { "http://localhost:3001/?query=here#frag" }
      let(:params) { { :a => 1 } }

      it "puts params before the fragment" do
        get.setup(easy)
        expect(easy.url).to eq("http://localhost:3001/?query=here&a=1#frag")
      end
    end

    context "when body" do
      let(:form) { { :a => 1 } }

      it "sets customrequest" do
        allow(easy).to receive(:customrequest=)
        get.setup(easy)
        expect(easy).to have_received(:customrequest=).with("GET")
      end

      context "when requesting" do
        before do
          get.setup(easy)
          easy.perform
        end

        it "sends a GET request with the body" do
          response = JSON.parse(easy.response_body)
          expect(response["REQUEST_METHOD"]).to eq("GET")
          expect(response["CONTENT_LENGTH"]).to eq("3")
          expect(response["CONTENT_TYPE"]).to include("application/x-www-form-urlencoded")
        end
      end
    end

    context "when no body" do
      it "clears customrequest" do
        allow(easy).to receive(:customrequest=)
        get.setup(easy)
        expect(easy).to have_received(:customrequest=).with(nil)
      end
    end

    context "when requesting" do
      before do
        get.setup(easy)
        easy.perform
      end

      context "when url already contains params" do
        let(:url) { "http://localhost:3001/?query=here" }
        let(:params) { {:a => "1&b=2"} }

        it "returns ok" do
          expect(easy.return_code).to eq(:ok)
        end

        it "is a get request" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
        end

        it "requests parameterized url" do
          expect(easy.effective_url).to eq("http://localhost:3001/?query=here&a=1%26b%3D2")
        end
      end

      context "when params and no body" do
        let(:params) { {:a => "1&b=2"} }

        it "returns ok" do
          expect(easy.return_code).to eq(:ok)
        end

        it "is a get request" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
        end

        it "requests parameterized url" do
          expect(easy.effective_url).to eq("http://localhost:3001/?a=1%26b%3D2")
        end
      end

      context "when params and body" do
        let(:params) { {:a => "1&b=2"} }
        let(:form) { {:b => "2"} }

        it "returns ok" do
          expect(easy.return_code).to eq(:ok)
        end

        it "is a get request" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
        end

        it "requests parameterized url" do
          expect(easy.effective_url).to eq("http://localhost:3001/?a=1%26b%3D2")
        end
      end

      context "with :escape" do
        let(:params) { {:a => "1&b=2"} }

        context 'missing' do
          it "escapes values" do
            expect(easy.url).to eq("#{url}?a=1%26b%3D2")
          end
        end

        context 'nil' do
          let(:options) { {:escape => nil} }

          it "escapes values" do
            expect(easy.url).to eq("#{url}?a=1%26b%3D2")
          end
        end

        context 'true' do
          let(:options) { {:escape => true} }

          it "escapes values" do
            expect(easy.url).to eq("#{url}?a=1%26b%3D2")
          end
        end

        context 'false' do
          let(:options) { {:escape => false} }

          it "sends raw values" do
            expect(easy.url).to eq("#{url}?a=1&b=2")
          end
        end
      end

    end
  end
end
