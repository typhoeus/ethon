require 'spec_helper'

describe Ethon::Easies::Util do
  class Dummy
    include Ethon::Easies::Util
  end

  let(:klass) { Dummy.new }

  describe "escape_zero_byte" do
    context "when value has no zero byte" do
      let(:value) { "hello world" }

      it "returns same value" do
        klass.escape_zero_byte(value).should be(value)
      end
    end

    context "when value has zero byte" do
      let(:value) { "hello \0world" }

      it "returns escaped" do
        klass.escape_zero_byte(value).should eq("hello \\0world")
      end
    end
  end
end
