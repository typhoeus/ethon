require 'spec_helper'

describe Orthos::Multi do
  let(:multi) { Orthos::Multi.new }

  describe ".new" do
    it "inits curl" do
      Orthos::Curl.expects(:init)
      multi
    end

    it "defines finalizer" do
      ObjectSpace.expects(:define_finalizer)
      multi
    end
  end

  describe "#handle" do
    it "returns a pointer" do
      multi.handle.should be_a(FFI::Pointer)
    end
  end
end
