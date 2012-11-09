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

        it "sets pipelining" do
          Ethon::Multi.any_instance.should_receive(:pipelining=).with(true)
          Ethon::Multi.new(options)
        end
      end
    end
  end

  describe ".finalizer" do
    let(:multi) { stub(:handle => 1) }

    it "calls multi_cleanup" do
      Ethon::Curl.should_receive(:multi_cleanup).with(1).at_least(1)
      Ethon::Multi.finalizer(multi).call
    end
  end
end
