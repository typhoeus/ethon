require 'spec_helper'

describe Ethon::Easies::ResponseCallbacks do
  let(:easy) { Ethon::Easy.new }

  describe "#trigger_callbacks" do
  end

  describe "#success?" do
    before do
      easy.return_code = return_code
      Ethon::Curl.
        expects(:get_info_long).
        with(:response_code, easy.handle).
        returns(response_code).at_most_once
    end

    context "when return code not 0" do
      let(:return_code) { 2 }
      let(:response_code) { 0 }

      it "returns false" do
        easy.success?.should be_false
      end
    end

    context "when return code 0" do
      let(:return_code) { 0 }

      context "when response code 0" do
        let(:response_code) { 0 }

        it "returns true" do
          easy.success?.should be_true
        end
      end

      context "when response code between 200 and 299" do
        let(:response_code) { 201 }

        it "returns true" do
          easy.success?.should be_true
        end
      end

      context "when response code not 0 and not between 200 and 299" do
        let(:response_code) { 301 }

        it "returns false" do
          easy.success?.should be_false
        end
      end
    end
  end

  [:success, :failure].each do |name|
    describe "#on_#{name}=" do
      it "assigns value" do
        eval "easy.on_#{name} {}"
        easy.instance_variable_get("@#{name}").should be_a(Proc)
      end
    end

    describe "##{name}" do
      before do
        eval "easy.on_#{name} {|e| e.response_code }"
        Ethon::Curl.expects(:get_info_long)
      end

      it "executes block and passes self" do
        easy.method(name).call
      end
    end
  end
end
