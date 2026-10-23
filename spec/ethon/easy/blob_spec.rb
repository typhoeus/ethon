# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::Blob do
  describe ".from_string" do
    it "copies the string into native memory" do
      blob = described_class.from_string("certificate")

      expect(blob[:len]).to eq("certificate".bytesize)
      expect(blob[:data].read_string("certificate".bytesize)).to eq("certificate")
      expect(blob[:flags]).to eq(0)
    end

    it "stores the flags" do
      expect(described_class.from_string("x", 1)[:flags]).to eq(1)
    end
  end
end

describe Ethon::Easy do
  let(:easy) { Ethon::Easy.new }
  let(:blob) { Ethon::Curl::Blob.from_string("certificate") }

  describe "#cainfo_blob=" do
    it "passes the blob pointer to libcurl" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :pointer, blob.to_ptr).and_return(:ok)

      easy.cainfo_blob = blob
    end

    it "retains the blob" do
      easy.cainfo_blob = blob

      expect(easy.instance_variable_get(:@blobs)[:cainfo_blob]).to be(blob)
    end

    it "releases the blob when set to nil" do
      easy.cainfo_blob = blob

      easy.cainfo_blob = nil

      expect(easy.instance_variable_get(:@blobs)).not_to have_key(:cainfo_blob)
    end

    it "rejects values that are not blobs or pointers" do
      expect { easy.cainfo_blob = "certificate" }.
        to raise_error(Ethon::Errors::InvalidValue)
      expect(easy.instance_variable_get(:@blobs)).to be_nil
    end

    it "shares retained blobs with a duplicate" do
      easy.cainfo_blob = blob

      copy = easy.dup

      expect(copy.instance_variable_get(:@blobs)).to eq(:cainfo_blob => blob)
    end

    it "clears retained blobs on reset" do
      easy.cainfo_blob = blob

      easy.reset

      expect(easy.instance_variable_get(:@blobs)).to be_nil
    end
  end
end
