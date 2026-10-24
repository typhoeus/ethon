# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'uri'

describe "cycling HTTP methods on one Easy" do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }

  def response
    JSON.parse(easy.response_body)
  end

  it "uses the latest method and body for every request" do
    requests = [
      [:get, nil],
      [:post, { :a => "1" }],
      [:put, { :b => "2" }],
      [:patch, { :c => "3" }],
      [:delete, { :d => "4" }],
      [:options, { :e => "5" }],
    ]

    requests.each do |method, body|
      if body
        easy.http_request(url, method, :body => body)
      else
        easy.http_request(url, method)
      end

      expect(easy.perform).to eq(:ok)
      expect(response["REQUEST_METHOD"]).to eq(method.to_s.upcase)
      expect(response["body"]).to eq(body ? URI.encode_www_form(body) : "")
    end
  end

  it "switches between HEAD and a body-carrying method" do
    easy.http_request(url, :post, :body => { :a => "1" })
    easy.perform

    easy.http_request(url, :head)
    expect(easy.perform).to eq(:ok)
    expect(easy.response_code).to eq(200)
    expect(easy.response_body).to be_empty

    easy.http_request(url, :get)
    expect(easy.perform).to eq(:ok)
    expect(response["REQUEST_METHOD"]).to eq("GET")
    expect(response["body"]).to eq("")
  end

  it "keeps a custom verb" do
    easy.http_request(url, :purge)
    expect(easy.perform).to eq(:ok)
    expect(response["REQUEST_METHOD"]).to eq("PURGE")
  end
end
