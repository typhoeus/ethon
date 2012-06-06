require 'spec_helper'

describe Orthos::Easies::Callbacks do
  let(:easy) { Orthos::Easy.new }

  describe "#set_callbacks" do
    before do
      Orthos::Curl.expects(:set_option).twice
    end

    it "sets write- and headerfunction" do
      easy.set_callbacks
    end

    it "resets @response_body" do
      easy.set_callbacks
      easy.instance_variable_get(:@response_body).should eq("")
    end

    it "resets @response_header" do
      easy.set_callbacks
      easy.instance_variable_get(:@response_header).should eq("")
    end
  end
end
