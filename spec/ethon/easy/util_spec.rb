# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Util do
  class Dummy
    include Ethon::Easy::Util
  end

  let(:klass) { Dummy.new }

  describe "escape_zero_byte" do
    context "when value has no zero byte" do
      let(:value) { "hello world" }

      it "returns same value" do
        expect(klass.escape_zero_byte(value)).to be(value)
      end
    end

    context "when value has zero byte" do
      let(:value) { "hello \0world" }

      it "returns escaped" do
        expect(klass.escape_zero_byte(value)).to eq("hello \\0world")
      end
    end
  end

  describe "validate_header_line" do
    it "returns a safe header line" do
      expect(klass.validate_header_line(:headers, "X-Test: 1")).
        to eq("X-Test: 1")
    end

    ["\r", "\n", "\0"].each do |byte|
      it "rejects a header line containing #{byte.inspect}" do
        expect { klass.validate_header_line(:headers, "X-Test: 1#{byte}") }.
          to raise_error(Ethon::Errors::InvalidValue, /headers/)
      end
    end
  end
end
