# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'stringio'

describe "reusing an Easy handle" do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }

  def response_body
    JSON.parse(easy.response_body)
  end

  it "uses the method of the latest request" do
    easy.http_request(url, :patch, :body => { :a => 1 })
    easy.http_request(url, :post, :body => { :a => 2 })

    easy.perform

    expect(response_body["REQUEST_METHOD"]).to eq("POST")
    expect(response_body["body"]).to eq("a=2")
  end

  it "clears a custom method for a GET request" do
    easy.http_request(url, :patch, :body => { :a => 1 })
    easy.http_request(url, :get)

    easy.perform

    expect(response_body["REQUEST_METHOD"]).to eq("GET")
  end

  it "clears a custom method for a POST request" do
    easy.http_request(url, :delete)
    easy.http_request(url, :post, :body => { :a => 2 })

    easy.perform

    expect(response_body["REQUEST_METHOD"]).to eq("POST")
    expect(response_body["body"]).to eq("a=2")
  end

  it "clears a custom method for a PUT request" do
    easy.http_request(url, :patch, :body => { :a => 1 })
    easy.http_request(url, :put, :body => { :a => 2 })

    easy.perform

    expect(response_body["REQUEST_METHOD"]).to eq("PUT")
  end

  it "clears the previous upload callback for a non-upload body" do
    easy.http_request(url, :put, :body => { :a => 1 })
    expect(easy.read_callback).to be_a(Proc)

    easy.http_request(url, :patch, :body => { :b => 2 })

    expect(easy.read_callback).to be_nil
  end

  it "replaces the response on every perform" do
    easy.http_request("#{url}first", :get)
    easy.perform

    easy.http_request("#{url}second", :get)
    easy.perform

    expect(easy.response_body).to include('"PATH_INFO":"/second"')
    expect(easy.response_body).not_to include('"PATH_INFO":"/first"')
    expect(easy.response_body.scan('"GATEWAY_INTERFACE"').size).to eq(1)
    expect(easy.response_headers.scan("HTTP/1.1").size).to eq(1)
  end

  it "calls on_headers for every perform" do
    calls = 0
    easy.on_headers { calls += 1 }

    easy.http_request(url, :get)
    easy.perform
    easy.http_request("#{url}second", :get)
    easy.perform

    expect(calls).to eq(2)
  end

  it "rewinds an upload body on every perform" do
    easy.url = url
    easy.upload = true
    easy.infilesize = 3
    easy.set_read_callback("abc")

    expect(easy.perform).to eq(:ok)
    expect(easy.response_body[/"body":"([^"]*)"/, 1]).to eq("abc")

    expect(easy.perform).to eq(:ok)
    expect(easy.response_body[/"body":"([^"]*)"/, 1]).to eq("abc")
  end

  it "rewinds a seekable IO upload body on every perform" do
    body = StringIO.new("hello-io")
    easy.url = url
    easy.upload = true
    easy.infilesize = body.string.bytesize
    easy.set_read_callback(body)

    2.times do
      expect(easy.perform).to eq(:ok)
      expect(response_body["body"]).to eq("hello-io")
    end
  end

  it "replays an IO upload body from its position when the callback was set" do
    body = StringIO.new("xxhello")
    body.seek(2)
    easy.url = url
    easy.upload = true
    easy.infilesize = 5
    easy.set_read_callback(body)

    2.times do
      expect(easy.perform).to eq(:ok)
      expect(response_body["body"]).to eq("hello")
    end
  end
end
