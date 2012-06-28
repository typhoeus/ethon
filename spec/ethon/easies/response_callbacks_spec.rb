require 'spec_helper'

describe Ethon::Easies::ResponseCallbacks do
  let(:easy) { Ethon::Easy.new }

  describe "#on_complete" do
    it "responds" do
      easy.should respond_to(:on_complete)
    end

    context "when no block given" do
      it "returns @on_complete" do
        easy.on_complete.should eq([])
      end
    end

    context "when block given" do
      it "stores" do
        easy.on_complete { p 1 }
        easy.instance_variable_get(:@on_complete).should have(1).items
      end
    end

    context "when multiple blocks given" do
      it "stores" do
        easy.on_complete { p 1 }
        easy.on_complete { p 2 }
        easy.instance_variable_get(:@on_complete).should have(2).items
      end
    end
  end

  describe "#complete" do
    before do
      easy.on_complete {|r| String.new(r.url) }
    end

    it "executes blocks and passes self" do
      String.expects(:new).with(easy.url)
      easy.complete
    end
  end
end
