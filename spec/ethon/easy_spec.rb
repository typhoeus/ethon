require 'spec_helper'

describe Ethon::Easy do
  let(:easy) { Ethon::Easy.new }

  describe ".new" do
    it "inits curl" do
      Ethon::Curl.expects(:init)
      easy
    end

    it "defines finalizer" do
      ObjectSpace.expects(:define_finalizer)
      easy
    end

    context "when options are empty" do
      it "sets nothing" do
        easy.instance_variables.all? { |ivar| ivar == nil }.should be_true
      end
    end

    context "when options not empty" do
      context "when verbose is set" do
        let(:options) { { :verbose => true } }
        let(:easy) { Ethon::Easy.new(options) }

        it "sets verbose" do
          easy.verbose.should be_true
        end
      end
    end
  end

  describe "#handle" do
    it "returns a pointer" do
      easy.handle.should be_a(FFI::Pointer)
    end
  end
end
