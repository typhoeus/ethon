require 'spec_helper'

describe Ethon::Easies::Form do
  let(:hash) { {} }
  let(:form) { Ethon::Easies::Form.new(hash) }

  describe ".new" do
    it "defines finalizer" do
      ObjectSpace.expects(:define_finalizer)
      form
    end

    it "assigns attribute to @params" do
      form.instance_variable_get(:@params).should eq(hash)
    end
  end

  describe "#first" do
    it "returns a pointer" do
      form.first.should be_a(FFI::MemoryPointer)
    end
  end

  describe "#last" do
    it "returns a pointer" do
      form.first.should be_a(FFI::MemoryPointer)
    end
  end

  describe "#multipart?" do
    before { form.instance_variable_set(:@query_pairs, pairs) }

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1'], ['b', '2']] }

      it "returns false" do
        form.multipart?.should be_false
      end
    end

    context "when query_pairs contains file" do
      let(:pairs) { [['a', '1'], ['b', ['path', 'encoding', 'abs_path']]] }

      it "returns true" do
        form.multipart?.should be_true
      end
    end
  end

  describe "#materialize" do
    before { form.instance_variable_set(:@query_pairs, pairs) }

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1']] }

      it "adds params to form" do
        Ethon::Curl.expects(:formadd)
        form.materialize
      end
    end

    context "when query_pairs contains file" do
      let(:pairs) { [['a', ["file", "type", "path/file"]]] }

      it "adds file to form" do
        Ethon::Curl.expects(:formadd)
        form.materialize
      end
    end
  end

  describe "#to_s" do
    context "when query_pairs empty" do
      before { form.instance_variable_set(:@query_pairs, []) }

      it "returns empty string" do
        form.to_s.should eq("")
      end
    end

    context "when query_pairs not empty" do
      context "when escape" do
        before do
          form.escape = true
          form.instance_variable_set(:@query_pairs, [[:a, "1&b=2"]])
        end

        it "returns concatenated escaped query string" do
          form.to_s.should eq("a=1%26b%3D2")
        end
      end

      context "when no escape" do
        before { form.instance_variable_set(:@query_pairs, [[:a, 1], [:b, 2]]) }

        it "returns concatenated query string" do
          form.to_s.should eq("a=1&b=2")
        end
      end
    end
  end
end
