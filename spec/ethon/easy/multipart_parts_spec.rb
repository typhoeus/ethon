# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'stringio'
require 'tempfile'

describe "multipart parts" do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/echo" }

  describe Ethon::Multipart::Part do
    it "requires a String or a File" do
      expect {
        described_class.new(StringIO.new("data"))
      }.to raise_error(ArgumentError, /String or a File/)
    end

    it "compares by value and metadata" do
      one = described_class.new("data", :filename => "a.txt", :content_type => "text/plain")
      two = described_class.new("data", :filename => "a.txt", :content_type => "text/plain")

      expect(one).to eq(two)
      expect(one.hash).to eq(two.hash)
      expect(one).not_to eq(described_class.new("data", :content_type => "text/plain"))
    end
  end

  it "sends a content type for a non-file part" do
    easy.http_request(
      url,
      :post,
      :body => {
        :metadata => Ethon::Multipart::Part.new(
          '{"a":1}',
          :content_type => "application/json"
        )
      }
    )

    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).to include(
      %(name="metadata"\r\nContent-Type: application/json\r\n\r\n{"a":1})
    )
  end

  it "does not add a filename for a non-file part" do
    easy.http_request(
      url,
      :post,
      :body => {
        :metadata => Ethon::Multipart::Part.new(
          '{"a":1}',
          :content_type => "application/json"
        )
      }
    )

    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).not_to include(%(name="metadata"; filename=))
  end

  it "sends in-memory data as a file part when a filename is given" do
    easy.http_request(
      url,
      :post,
      :body => {
        :note => Ethon::Multipart::Part.new(
          "hello",
          :filename => "note.txt",
          :content_type => "text/plain"
        )
      }
    )

    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).to include(
      %(name="note"; filename="note.txt"\r\nContent-Type: text/plain\r\n\r\nhello)
    )
  end

  it "overrides the filename and content type of a file part" do
    Tempfile.create do |file|
      file.write("file contents")
      file.flush

      File.open(file.path) do |upload|
        easy.http_request(
          "http://localhost:3001/file",
          :post,
          :body => {
            :file => Ethon::Multipart::Part.new(
              upload,
              :filename => "report.txt",
              :content_type => "text/custom"
            )
          }
        )
      end

      expect(easy.perform).to eq(:ok)
      response = JSON.parse(easy.response_body)
      expect(response["filename"]).to eq("report.txt")
      expect(response["content-type"]).to eq("text/custom")
      expect(response["content"]).to eq("file contents")
    end
  end

  it "keeps the detected metadata for a file part without overrides" do
    Tempfile.create do |file|
      file.write("file contents")
      file.flush

      File.open(file.path) do |upload|
        easy.http_request(
          "http://localhost:3001/file",
          :post,
          :body => { :file => Ethon::Multipart::Part.new(upload) }
        )
      end

      expect(easy.perform).to eq(:ok)
      response = JSON.parse(easy.response_body)
      expect(response["filename"]).to eq(File.basename(file.path))
      expect(response["content-type"]).to eq("application/octet-stream")
      expect(response["content"]).to eq("file contents")
    end
  end

  it "rejects a content type that would add a header" do
    expect {
      easy.http_request(
        url,
        :post,
        :body => {
          :metadata => Ethon::Multipart::Part.new(
            "data",
            :content_type => "text/plain\r\nX-Injected: yes"
          )
        }
      )
    }.to raise_error(Ethon::Errors::InvalidValue, /type/)
  end

  it "rejects a filename that would add a header" do
    expect {
      easy.http_request(
        url,
        :post,
        :body => {
          :metadata => Ethon::Multipart::Part.new(
            "data",
            :filename => "note\r\nX-Injected: yes.txt"
          )
        }
      )
    }.to raise_error(Ethon::Errors::InvalidValue, /filename/)
  end

  context "with the form API" do
    before do
      skip "curl_formadd is unavailable" unless Ethon::Curl.respond_to?(:formadd)

      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:mime_init).and_return(false)
    end

    it "sends a content type for a non-file part" do
      easy.http_request(
        url,
        :post,
        :body => {
          :metadata => Ethon::Multipart::Part.new(
            '{"a":1}',
            :content_type => "application/json"
          )
        }
      )

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include(
        %(name="metadata"\r\nContent-Type: application/json\r\n\r\n{"a":1})
      )
    end

    it "sends in-memory data as a file part when a filename is given" do
      easy.http_request(
        url,
        :post,
        :body => {
          :note => Ethon::Multipart::Part.new(
            "hello",
            :filename => "note.txt",
            :content_type => "text/plain"
          )
        }
      )

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include(
        %(name="note"; filename="note.txt"\r\nContent-Type: text/plain\r\n\r\nhello)
      )
    end

    it "overrides the filename and content type of a file part" do
      Tempfile.create do |file|
        file.write("file contents")
        file.flush

        File.open(file.path) do |upload|
          easy.http_request(
            "http://localhost:3001/file",
            :post,
            :body => {
              :file => Ethon::Multipart::Part.new(
                upload,
                :filename => "report.txt",
                :content_type => "text/custom"
              )
            }
          )
        end

        expect(easy.perform).to eq(:ok)
        response = JSON.parse(easy.response_body)
        expect(response["filename"]).to eq("report.txt")
        expect(response["content-type"]).to eq("text/custom")
        expect(response["content"]).to eq("file contents")
      end
    end
  end
end
