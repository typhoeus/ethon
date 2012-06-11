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
      it "sends header" do
        easy.set_headers
        easy.url = "http://localhost:3001"
        easy.prepare
        easy.perform
        easy.response_body.should include('"HTTP_USER_AGENT":"Ethon"')
      end
    end
  end
end
