require 'spec_helper'

describe Ethon::Easies::Header do
  let(:easy) { Ethon::Easy.new }

  describe "#set_headers" do
    let(:headers) { { 'User-Agent' => 'Ethon' } }
    before { easy.headers = headers }

    it "sets header" do
      Ethon::Curl.should_receive(:set_option)
      easy.set_headers
    end

    context "when requesting" do
      before do
        easy.set_headers
        easy.url = "http://localhost:3001"
        easy.prepare
        easy.perform
      end

      it "sends" do
        expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon"')
      end

      context "when header value contains null byte" do
        let(:headers) { { 'User-Agent' => "Ethon\0" } }

        it "escapes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon\\\\0"')
        end
      end

      context "when header value has leading whitespace" do
        let(:headers) { { 'User-Agent' => " Ethon" } }

        it "removes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon"')
        end
      end

      context "when header value has traiing whitespace" do
        let(:headers) { { 'User-Agent' => "Ethon " } }

        it "removes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon"')
        end
      end
    end
  end

  describe "#compose_header" do
    it "has space in between" do
      expect(easy.compose_header('a', 'b')).to eq('a: b')
    end

    context "when value is a symbol" do
      it "works" do
        expect{ easy.compose_header('a', :b) }.to_not raise_error
      end
    end
  end

  describe "#header_list" do
    context "when no set_headers" do
      it "returns nil" do
        expect(easy.header_list).to eq(nil)
      end
    end

    context "when set_headers" do
      it "returns pointer to header list" do
        easy.headers = {'User-Agent' => 'Custom'}
        easy.set_headers
        expect(easy.header_list).to be_a(FFI::Pointer)
      end
    end
  end
end
