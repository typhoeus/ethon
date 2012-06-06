require 'spec_helper'

describe Ethon::Easies::Form do
  let(:hash) { {} }
  let(:params) { Ethon::Easies::Form.new(hash) }

  describe ".new" do
    it "defines finalizer" do
      ObjectSpace.expects(:define_finalizer)
      params
    end

    it "assigns attribute to @params" do
      params.instance_variable_get(:@params).should eq(hash)
    end
  end

  describe "#first" do
    it "returns a pointer" do
      params.first.should be_a(FFI::MemoryPointer)
    end
  end

  describe "#last" do
    it "returns a pointer" do
      params.first.should be_a(FFI::MemoryPointer)
    end
  end

  describe "#multipart?" do
    before { params.instance_variable_set(:@query_pairs, pairs) }

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1'], ['b', '2']] }

      it "returns false" do
        params.multipart?.should be_false
      end
    end

    context "when query_pairs contains file" do
      let(:file) { File.new("Rakefile", "r") }
      let(:pairs) { [['a', '1'], ['b', file]] }

      it "returns false" do
        params.multipart?.should be_true
      end
    end

    context "when query_pairs contains tempfile" do
      let(:file) { Tempfile.new("fubar") }
      let(:pairs) { [['a', '1'], ['b', file]] }

      it "returns false" do
        params.multipart?.should be_true
      end
    end
  end

  describe "#materialize" do
    before { params.instance_variable_set(:@query_pairs, pairs) }

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1']] }

      it "adds params to form" do
        Ethon::Curl.expects(:formadd)
        params.materialize
      end
    end

    context "when query_pairs contains file" do
      let(:pairs) { [['a', ["file", "type", "path/file"]]] }

      it "adds file to form" do
        Ethon::Curl.expects(:formadd)
        params.materialize
      end
    end
  end
end
