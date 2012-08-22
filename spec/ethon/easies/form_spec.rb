require 'spec_helper'

describe Ethon::Easies::Form do
  let(:hash) { {} }
  let!(:easy) { Ethon::Easy.new }
  let(:form) { Ethon::Easies::Form.new(easy, hash) }

  describe ".new" do
    it "defines finalizer" do
      ObjectSpace.should_receive(:define_finalizer)
      form
    end

    it "assigns attribute to @params" do
      expect(form.instance_variable_get(:@params)).to eq(hash)
    end
  end

  describe "#first" do
    it "returns a pointer" do
      expect(form.first).to be_a(FFI::MemoryPointer)
    end
  end

  describe "#last" do
    it "returns a pointer" do
      expect(form.first).to be_a(FFI::MemoryPointer)
    end
  end

  describe "#multipart?" do
    before { form.instance_variable_set(:@query_pairs, pairs) }

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1'], ['b', '2']] }

      it "returns false" do
        expect(form.multipart?).to be_false
      end
    end

    context "when query_pairs contains file" do
      let(:pairs) { [['a', '1'], ['b', ['path', 'encoding', 'abs_path']]] }

      it "returns true" do
        expect(form.multipart?).to be_true
      end
    end
  end

  describe "#materialize" do
    before { form.instance_variable_set(:@query_pairs, pairs) }

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1']] }

      it "adds params to form" do
        Ethon::Curl.should_receive(:formadd)
        form.materialize
      end
    end

    context "when query_pairs contains nil" do
      let(:pairs) { [['a', nil]] }

      it "adds params to form" do
        Ethon::Curl.should_receive(:formadd)
        form.materialize
      end
    end

    context "when query_pairs contains file" do
      let(:pairs) { [['a', ["file", "type", "path/file"]]] }

      it "adds file to form" do
        Ethon::Curl.should_receive(:formadd)
        form.materialize
      end
    end
  end
end
