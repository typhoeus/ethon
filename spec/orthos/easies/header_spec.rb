require 'spec_helper'

describe Orthos::Easies::Header do
  let(:easy) { Orthos::Easy.new }

  describe "#set_headers" do
    let(:headers) { { 'User-Agent' => 'Orthos' } }
    before { easy.headers = headers }

    it "sets header" do
      Orthos::Curl.expects(:set_option)
      easy.set_headers
    end
  end
end
