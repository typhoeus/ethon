# frozen_string_literal: true
require 'spec_helper'
require 'digest'
require 'json'
require 'tempfile'

describe "multipart forms" do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/multipart" }

  it "round-trips values that need escaping" do
    fields = {
      :alpha => "one",
      :unicode => "héllo ☃",
      :empty => "",
      :punctuation => "a&b=c/d?e#f",
      :multiline => "first\nsecond"
    }
    easy.http_request(url, :post, :body => fields, :multipart => true)

    expect(easy.perform).to eq(:ok)
    response = JSON.parse(easy.response_body)
    expect(response).to include(
      "alpha" => "one",
      "unicode" => "héllo ☃",
      "empty" => "",
      "punctuation" => "a&b=c/d?e#f",
      "multiline" => "first\nsecond"
    )
  end

  it "round-trips nested keys and arrays" do
    body = {
      :nested => { :key => "value" },
      :list => ["first", "second"]
    }
    easy.http_request(
      url,
      :post,
      :body => body,
      :multipart => true,
      :params_encoding => :rack
    )

    expect(easy.perform).to eq(:ok)
    response = JSON.parse(easy.response_body)
    expect(response["nested"]).to eq("key" => "value")
    expect(response["list"]).to eq(["first", "second"])
  end

  it "uses indexed keys with the default params encoding" do
    easy.http_request(
      url,
      :post,
      :body => { :list => ["first", "second"] },
      :multipart => true
    )

    expect(easy.perform).to eq(:ok)
    response = JSON.parse(easy.response_body)
    expect(response["list"]).to eq("0" => "first", "1" => "second")
  end

  it "keeps array values under params_encoding :none" do
    body = { :list => ["first", "second"], :triple => ["a", "b", "c"] }
    easy.http_request(
      url,
      :post,
      :body => body,
      :multipart => true,
      :params_encoding => :none
    )

    expect(easy.perform).to eq(:ok)
    response = JSON.parse(easy.response_body)
    expect(response["list"]).to eq(["first", "second"].to_s)
    expect(response["triple"]).to eq(["a", "b", "c"].to_s)
  end

  it "uploads a binary file byte for byte" do
    content = (0..255).to_a.pack("C*") * 4

    Tempfile.create do |file|
      file.binmode
      file.write(content)
      file.flush

      File.open(file.path) do |upload|
        easy.http_request(
          url,
          :post,
          :body => { :field => "value", :file => upload }
        )
      end

      expect(easy.perform).to eq(:ok)
      response = JSON.parse(easy.response_body)
      expect(response["field"]).to eq("value")
      expect(response["file"]).to include(
        "filename" => File.basename(file.path),
        "size" => content.bytesize,
        "sha256" => Digest::SHA256.hexdigest(content)
      )
    end
  end

  it "handles multiple files under different names" do
    contents = ["first file", "second file"]

    Tempfile.create do |first|
      Tempfile.create do |second|
        [first, second].each_with_index do |file, index|
          file.binmode
          file.write(contents[index])
          file.flush
        end

        File.open(first.path) do |first_upload|
          File.open(second.path) do |second_upload|
            easy.http_request(
              url,
              :post,
              :body => {
                :first => first_upload,
                :second => second_upload,
                :note => "both"
              }
            )
          end
        end

        expect(easy.perform).to eq(:ok)
        response = JSON.parse(easy.response_body)
        expect(response["note"]).to eq("both")
        expect(response["first"]["sha256"]).to eq(Digest::SHA256.hexdigest(contents[0]))
        expect(response["second"]["sha256"]).to eq(Digest::SHA256.hexdigest(contents[1]))
      end
    end
  end
end
