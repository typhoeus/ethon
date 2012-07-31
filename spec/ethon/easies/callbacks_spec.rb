require 'spec_helper'

describe Ethon::Easies::Callbacks do
  let(:easy) { Ethon::Easy.new }

  describe "#set_callbacks" do
    before do
      Ethon::Curl.should_receive(:set_option).twice
    end

    it "sets write- and headerfunction" do
      easy.set_callbacks
    end

    it "resets @response_body" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@response_body)).to eq("")
    end

    it "resets @response_header" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@response_header)).to eq("")
    end
  end
end
