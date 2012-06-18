require 'spec_helper'

describe Ethon::Easies::Header do
  let(:easy) { Ethon::Easy.new }

  describe "#set_headers" do
    let(:headers) { { 'User-Agent' => 'Ethon' } }
    before { easy.headers = headers }

    it "sets header" do
      Ethon::Curl.expects(:set_option)
      easy.set_headers
    end

    context "when requesting" do
      before do
        easy.set_headers
        easy.url = "http://localhost:3001"
        easy.prepare
        easy.perform
      end

      it "sends header" do
        easy.response_body.should include('"HTTP_USER_AGENT":"Ethon"')
      end

      context "when header value contains null byte" do
        let(:headers) { { 'User-Agent' => "Ethon\0" } }

        it "escapes" do
          easy.response_body.should include('"HTTP_USER_AGENT":"Ethon\\\\0"')
        end
      end
    end
  end

  describe "#compose_headers" do
    context "when value is a symbol" do
      it "doesn't fail" do
        expect{ easy.compose_header('a', :b) }.to_not raise_error
      end
    end
  end
end
