require 'spec_helper'

describe Ethon::Easies::ResponseCallbacks do
  let(:easy) { Ethon::Easy.new }

  describe "#on_complete=" do
    it "assigns value" do
      easy.on_complete {}
      easy.instance_variable_get("@complete").should be_a(Proc)
    end
  end

  describe "#complete" do
    before do
      easy.on_complete {|e| e.response_code }
      Ethon::Curl.expects(:get_info_long)
    end

    it "executes block and passes self" do
      easy.complete
    end
  end
end
