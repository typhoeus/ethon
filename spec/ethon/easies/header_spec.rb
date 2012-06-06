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
  end
end
