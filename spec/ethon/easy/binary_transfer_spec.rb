# frozen_string_literal: true
require 'spec_helper'
require 'stringio'
require 'tempfile'

describe "binary transfers" do
  let(:easy) { Ethon::Easy.new }
  let(:pattern) { (0..255).to_a.pack("C*") }
  let(:size) { 100_000 }
  let(:payload) { (pattern * (size / pattern.bytesize + 1)).byteslice(0, size) }
  let(:url) { "http://localhost:3001" }

  describe "downloading" do
    it "returns every byte unchanged" do
      easy.url = "#{url}/binary/#{payload.bytesize}"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq(payload)
      expect(easy.response_body.bytesize).to eq(payload.bytesize)
      expect(easy.size_download_t).to eq(payload.bytesize)
    end

    it "keeps the body binary instead of transcoding it" do
      easy.url = "#{url}/binary/#{payload.bytesize}"
      easy.perform

      expect(easy.response_body.encoding).to eq(Encoding::ASCII_8BIT)
      expect(easy.response_body.valid_encoding?).to be(true)
    end

    it "keeps structured headers readable next to a binary body" do
      skip "curl_easy_header is unavailable" unless Ethon::Curl.respond_to?(:easy_header)

      easy.url = "#{url}/binary/16"
      easy.perform

      expect(easy.header("Content-Type").value).to eq("application/octet-stream")
      expect(easy.response_body).to eq(payload.byteslice(0, 16))
    end

    it "yields the same bytes through on_body" do
      chunks = []
      easy.url = "#{url}/binary/#{payload.bytesize}"
      easy.on_body { |chunk| chunks << chunk }

      expect(easy.perform).to eq(:ok)
      expect(chunks.join).to eq(payload)
      expect(easy.response_body).to be_empty
      expect(chunks.size).to be > 1
    end

    it "writes the same bytes when streaming to a file" do
      Tempfile.create do |file|
        file.close
        easy.url = "#{url}/binary/#{payload.bytesize}"
        easy.file = file.path

        expect(easy.perform).to eq(:ok)
        expect(File.binread(file.path)).to eq(payload)
      end
    end

    it "keeps delivering every byte when the handle is reused" do
      easy.url = "#{url}/binary/#{payload.bytesize}"

      2.times do
        expect(easy.perform).to eq(:ok)
        expect(easy.response_body).to eq(payload)
      end
    end
  end

  describe "uploading" do
    before do
      easy.headers = {
        "Expect" => "",
        "Content-Type" => "application/octet-stream"
      }
    end

    it "posts a binary body without losing null bytes" do
      easy.http_request("#{url}/echo", :post, :body => payload)

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq(payload)
    end

    it "puts a binary body through a read callback" do
      body = payload.byteslice(0, 4_096)
      easy.url = "#{url}/echo"
      easy.upload = true
      easy.infilesize = body.bytesize
      easy.set_read_callback(StringIO.new(body))

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq(body)
    end

    it "replays a seekable upload body on every perform" do
      body = StringIO.new(payload.byteslice(0, 4_096))
      easy.url = "#{url}/echo"
      easy.upload = true
      easy.infilesize = body.size
      easy.set_read_callback(body)

      2.times do
        expect(easy.perform).to eq(:ok)
        expect(easy.response_body).to eq(body.string)
      end
    end
  end
end
