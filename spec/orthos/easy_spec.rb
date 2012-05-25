require 'spec_helper'

describe Orthos::Easy do
  let(:easy) { Orthos::Easy.new }

  describe ".new" do
    it "inits curl" do
      Orthos::Curl.expects(:init)
      easy
    end

    it "defines finalizer" do
      ObjectSpace.expects(:define_finalizer)
      easy
    end
  end

  describe "#handle" do
    it "returns a pointer" do
      easy.handle.should be_a(FFI::Pointer)
    end
  end
end
