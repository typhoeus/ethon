# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'tempfile'

describe Ethon::Curl::Mime do
  let(:easy) { Ethon::Easy.new }
  let(:mime) { described_class.new(easy) }

  describe "#addpart" do
    it "returns a part owned by the mime" do
      part = mime.addpart

      expect(part).to be_a(Ethon::Curl::MimePart)
      expect(part.mime).to be(mime)
    end

    it "raises when libcurl cannot allocate a part" do
      allow(Ethon::Curl).to receive(:mime_addpart).and_return(FFI::Pointer::NULL)

      expect { mime.addpart }.to raise_error(NoMemoryError, "curl_mime_addpart failed")
    end
  end

  describe "MimePart" do
    let(:part) { mime.addpart }

    it "sets form fields" do
      expect {
        part.name = "field"
        part.data = "value"
        part.type = "text/plain"
      }.not_to raise_error
    end

    it "sets files" do
      Tempfile.create do |file|
        file.write("contents")
        file.flush

        part.name = "file"
        part.file = file.path

        expect(part.handle).to be_a(FFI::Pointer)
      end
    end

    it "sets an encoder" do
      expect(part.encoder = "base64").to eq("base64")
    end

    it "raises when a curl_mime_* call fails" do
      allow(Ethon::Curl).to receive(:mime_name).and_return(:out_of_memory)

      expect { part.name = "field" }.to raise_error(Ethon::Errors::Mime, /memory/i)
    end

    it "raises when curl_mime_headers fails" do
      allow(Ethon::Curl).to receive(:mime_headers).and_return(:out_of_memory)

      expect { part.headers = ["X-Test: 1"] }.
        to raise_error(Ethon::Errors::Mime, /memory/i)
    end

    it "releases a partially built header list when an append fails" do
      first = FFI::MemoryPointer.new(:pointer)
      allow(Ethon::Curl).to receive(:slist_append).and_return(first, FFI::Pointer::NULL)
      expect(Ethon::Curl).to receive(:slist_free_all).with(first)

      expect { part.headers = ["X-First: 1", "X-Second: 2"] }.
        to raise_error(NoMemoryError, "curl_slist_append failed")
    end

    it "frees the generated header list when libcurl rejects it" do
      list = FFI::MemoryPointer.new(:int)
      allow(Ethon::Curl).to receive(:slist_append).and_return(list)
      allow(Ethon::Curl).to receive(:mime_headers).and_return(:out_of_memory)
      expect(Ethon::Curl).to receive(:slist_free_all).with(list)

      expect { part.headers = { "X-Test" => "1" } }.
        to raise_error(Ethon::Errors::Mime, /memory/i)
    end

    it "keeps a caller-owned header list alive until it is replaced" do
      list = Ethon::Curl::Slist.new(Ethon::Curl.slist_append(nil, "X-Test: 1"))
      part.headers = list
      expect(part.instance_variable_get(:@headers_list)).to be(list)

      allow(Ethon::Curl).to receive(:mime_headers).and_return(:out_of_memory)
      expect { part.headers = { "X-Other" => "2" } }.
        to raise_error(Ethon::Errors::Mime)
      expect(part.instance_variable_get(:@headers_list)).to be(list)
    end
  end

  describe "#initialize" do
    it "raises when the MIME API is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:mime_init).and_return(false)

      expect { described_class.new(easy) }.
        to raise_error(NotImplementedError, /curl_mime_init/)
    end
  end

  describe "Easy integration" do
    let(:mime) { described_class.new(easy) }

    it "retains the MIME structure on the Easy" do
      easy.mime = mime

      expect(easy.mime).to be(mime)
      expect(easy.instance_variable_get(:@mime)).to be(mime)
    end

    it "clears the MIME structure" do
      easy.mime = mime

      easy.mime = nil

      expect(easy.mime).to be_nil
    end

    it "posts a file part" do
      Tempfile.create do |file|
        file.write("mime content")
        file.flush

        easy.url = "http://localhost:3001/file"
        part = mime.addpart
        part.name = "file"
        part.file = file.path
        easy.mime = mime

        expect(easy.perform).to eq(:ok)
        body = JSON.parse(easy.response_body)
        expect(body["filename"]).to eq(File.basename(file.path))
        expect(body["content"]).to eq("mime content")
      end
    end

    it "posts a data part" do
      easy.url = "http://localhost:3001/"
      part = mime.addpart
      part.name = "field"
      part.data = "value"
      easy.mime = mime

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include("field")
      expect(easy.response_body).to include("value")
    end

    it "encodes a data part" do
      easy.url = "http://localhost:3001/"
      part = mime.addpart
      part.name = "field"
      part.data = "hello"
      part.encoder = "base64"
      easy.mime = mime

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include("aGVsbG8=")
    end

    it "posts a part with extra headers" do
      easy.url = "http://localhost:3001/"
      part = mime.addpart
      part.name = "field"
      part.data = "value"
      part.headers = { "X-Test" => "1" }
      easy.mime = mime

      expect(easy.perform).to eq(:ok)
    end

    it "clears the MIME structure on reset" do
      easy.mime = mime

      easy.reset

      expect(easy.mime).to be_nil
    end

    it "clears a previous MIME body when setting up an empty request" do
      easy.mime = mime
      post = Ethon::Easy::Http::Post.new("http://localhost:3001/", {})

      post.setup(easy)

      expect(easy.mime).to be_nil
    end

    it "resets the method after clearing a MIME body on a reused handle" do
      easy.mime = mime
      easy.http_request("http://localhost:3001/", :get, {})

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
    end

    it "rejects a MIME structure created before fork" do
      allow(mime).to receive(:check_pid!).and_raise(Ethon::Errors::ForkSafety.new)

      expect { easy.mime = mime }.to raise_error(Ethon::Errors::ForkSafety)
    end
  end
end
