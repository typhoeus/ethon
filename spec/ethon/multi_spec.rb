require 'spec_helper'

describe Ethon::Multi do
  let(:multi) { Ethon::Multi.new }

  describe ".new" do
    it "inits curl" do
      Ethon::Curl.expects(:init)
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
