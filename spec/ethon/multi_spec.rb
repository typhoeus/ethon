require 'spec_helper'

describe Ethon::Multi do
  let(:multi) { Ethon::Multi.new }

  describe ".new" do
    it "inits curl" do
      Ethon::Curl.should_receive(:init)
      multi
    end

    it "defines finalizer" do
      ObjectSpace.should_receive(:define_finalizer)
      multi
    end

    context "when options not empty" do
      context "when pipelining is set" do
        let(:options) { { :pipelining => true } }
        let(:multi) { Ethon::Multi.new(options) }

        it "sets pipelining" do
          expect(multi.pipelining).to be_true
        end
      end
    end
  end

  describe ".finalizer" do
    it "calls multi_cleanup" do
      Ethon::Curl.should_receive(:multi_cleanup).with(multi.handle)
      Ethon::Multi.finalizer(multi).call
    end

    it "works" do
      expect{ Ethon::Multi.finalizer(multi).call }.to_not raise_error
    end
  end
end
