require 'spec_helper'

describe Ethon::Easy::ResponseCallbacks do
  let(:easy) { Ethon::Easy.new }

  describe "#on_complete" do
    it "responds" do
      expect(easy).to respond_to(:on_complete)
    end

    context "when no block given" do
      it "returns @on_complete" do
        expect(easy.on_complete).to eq([])
      end
    end

    context "when block given" do
      it "stores" do
        easy.on_complete { p 1 }
        expect(easy.instance_variable_get(:@on_complete)).to have(1).items
      end
    end

    context "when multiple blocks given" do
      it "stores" do
        easy.on_complete { p 1 }
        easy.on_complete { p 2 }
        expect(easy.instance_variable_get(:@on_complete)).to have(2).items
      end
    end
  end

  describe "#complete" do
    before do
      easy.on_complete {|r| String.new(r.url) }
    end

    it "executes blocks and passes self" do
      String.should_receive(:new).with(easy.url)
      easy.complete
    end

    context "when @on_complete nil" do
      it "doesn't raise" do
        easy.instance_variable_set(:@on_complete, nil)
        expect{ easy.complete }.to_not raise_error(NoMethodError)
      end
    end
  end
end
