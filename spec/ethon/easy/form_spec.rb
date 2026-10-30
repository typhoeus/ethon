# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Form do
  let(:hash) { {} }
  let!(:easy) { Ethon::Easy.new }
  let(:form) { Ethon::Easy::Form.new(easy, hash) }

  describe ".new" do
    it "assigns attribute to @params" do
      expect(form.instance_variable_get(:@params)).to eq(hash)
    end
  end

  describe "#first" do
    it "returns a pointer" do
      expect(form.first).to be_a(FFI::Pointer)
    end
  end

  describe "#last" do
    it "returns a pointer" do
      expect(form.last).to be_a(FFI::Pointer)
    end
  end

  describe "#multipart?" do
    before { form.instance_variable_set(:@query_pairs, pairs) }

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1'], ['b', '2']] }

      it "returns false" do
        expect(form.multipart?).to be_falsey
      end
    end

    context "when params contain a file" do
      let(:pairs) { nil }
      let(:file) { File.open(__FILE__) }
      let(:hash) { { :file => file } }

      after { file.close }

      it "returns true" do
        expect(form.multipart?).to be_truthy
      end
    end

    context "when params contain a multipart part without a file" do
      let(:pairs) { nil }
      let(:hash) {
        { :field => Ethon::Multipart::Part.new("value", :content_type => "text/plain") }
      }

      it "returns true" do
        expect(form.multipart?).to be_truthy
      end
    end

    context "when options contains multipart=true" do
      before { form.instance_variable_set(:@multipart, true) }
      let(:pairs) { [['a', '1'], ['b', '2']] }

      it "returns true" do
        expect(form.multipart?).to be_truthy
      end
    end

    context "when params_encoding is :none and a value is an array" do
      let(:hash) { { :a => [1, 2] } }
      let(:pairs) { nil }

      before { form.params_encoding = :none }

      it "returns false" do
        expect(form.multipart?).to be_falsey
      end
    end
  end

  describe "#materialize" do
    before do
      skip "curl_formadd is unavailable" unless Ethon::Curl.respond_to?(:formadd)

      form.instance_variable_set(:@query_pairs, pairs)
    end

    context "when curl_formadd is unavailable" do
      let(:pairs) { [['a', '1']] }

      it "raises a helpful error" do
        allow(Ethon::Curl).to receive(:respond_to?).and_call_original
        allow(Ethon::Curl).to receive(:respond_to?).with(:formadd).and_return(false)

        expect { form.materialize }.
          to raise_error(NotImplementedError, /MIME API/)
      end
    end

    context "when query_pairs contains string values" do
      let(:pairs) { [['a', '1']] }

      it "adds params to form" do
        expect(Ethon::Curl).to receive(:formadd).and_return(0)
        form.materialize
      end
    end

    context "when query_pairs contains nil" do
      let(:pairs) { [['a', nil]] }

      it "adds params to form" do
        expect(Ethon::Curl).to receive(:formadd).and_return(0)
        form.materialize
      end
    end

    context "when query_pairs contains file" do
      let(:pairs) { [['a', Ethon::Easy::Queryable::FileInfo.new("file", "type", "path/file")]] }

      it "adds file to form" do
        expect(Ethon::Curl).to receive(:formadd).and_return(0)
        form.materialize
      end
    end

    context "when query_pairs contains file and string values" do
      let(:pairs) { [['a', Ethon::Easy::Queryable::FileInfo.new("file", "type", "path/file")], ['b', '1']] }

      it "adds file to form" do
        expect(Ethon::Curl).to receive(:formadd).twice.and_return(0)
        form.materialize
      end
    end

    context "when a field name contains CRLF" do
      let(:pairs) { [["field\r\nX-Injected: yes", "value"]] }

      it "rejects the field before building the form" do
        expect(Ethon::Curl).not_to receive(:formadd)

        expect { form.materialize }.
          to raise_error(Ethon::Errors::InvalidValue, /name/)
      end
    end

    context "when a filename contains CRLF" do
      let(:pairs) { [['file', Ethon::Easy::Queryable::FileInfo.new("file\r\nX-Injected: yes", "text/plain", "path/file")]] }

      it "rejects the file before building the form" do
        expect(Ethon::Curl).not_to receive(:formadd)

        expect { form.materialize }.
          to raise_error(Ethon::Errors::InvalidValue, /filename/)
      end
    end

    context "when a content type contains CRLF" do
      let(:pairs) { [['file', Ethon::Easy::Queryable::FileInfo.new("file", "text/plain\r\nX-Injected: yes", "path/file")]] }

      it "rejects the file before building the form" do
        expect(Ethon::Curl).not_to receive(:formadd)

        expect { form.materialize }.
          to raise_error(Ethon::Errors::InvalidValue, /content_type/)
      end
    end

    context "when query_pairs contains file, string and int values" do
      let(:pairs) { [['a', Ethon::Easy::Queryable::FileInfo.new("file", "type", "path/file")], ['b', '1'], ['c', 1]] }

      it "adds file to form" do
        expect(Ethon::Curl).to receive(:formadd).exactly(3).times.and_return(0)
        form.materialize
      end
    end
  end

  describe "when a multipart body is a raw String" do
    let(:raw_form) { described_class.new(easy, "raw", true) }

    it "rejects a MIME body without field names" do
      expect { raw_form.mime }.
        to raise_error(ArgumentError, /multipart bodies require a Hash of fields/)
    end

    it "rejects a form API body without field names" do
      skip "curl_formadd is unavailable" unless Ethon::Curl.respond_to?(:formadd)

      expect { raw_form.materialize }.
        to raise_error(ArgumentError, /multipart bodies require a Hash of fields/)
    end
  end
end
