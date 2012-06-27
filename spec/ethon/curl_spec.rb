require 'spec_helper'

describe Ethon::Curl do
  describe ".init" do
    before { Ethon::Curl.class_variable_set(:@@initialized, false) }

    context "when global_init fails" do
      it "raises global init error" do
        Ethon::Curl.expects(:global_init).returns(1)
        expect{ Ethon::Curl.init }.to raise_error(Ethon::Errors::GlobalInit)
      end
    end

    context "when global_init works" do
      it "doesn't raises global init error" do
        Ethon::Curl.expects(:global_init).returns(0)
        expect{ Ethon::Curl.init }.to_not raise_error(Ethon::Errors::GlobalInit)
      end
    end
  end
end
