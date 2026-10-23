# frozen_string_literal: true
require 'spec_helper'
require 'json'

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
end
