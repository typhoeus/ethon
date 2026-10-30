# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'tmpdir'

describe "cookies" do
  let(:easy) { Ethon::Easy.new }

  before do
    # An empty cookie file enables the in-memory cookie engine.
    easy.cookiefile = ""
    easy.url = "http://localhost:3001/set-cookie"
    easy.perform
  end

  after { easy.cleanup }

  it "stores a cookie set by the server" do
    expect(easy.return_code).to eq(:ok)
    expect(easy.cookielist).to include(a_string_matching(/name\tvalue/))
  end

  it "sends the stored cookie on the next request" do
    easy.url = "http://localhost:3001/"
    easy.perform

    expect(easy.return_code).to eq(:ok)
    expect(JSON.parse(easy.response_body)["HTTP_COOKIE"]).to eq("name=value")
  end

  it "keeps cookies when the handle is reset" do
    # curl_easy_reset keeps the cookie store, but reset turns the cookie
    # engine off, so re-enable it before the next request.
    easy.reset
    easy.cookiefile = ""
    easy.url = "http://localhost:3001/"
    easy.perform

    expect(JSON.parse(easy.response_body)["HTTP_COOKIE"]).to eq("name=value")
  end

  it "writes and reads a cookie jar" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "cookies.txt")
      writer = Ethon::Easy.new(
        :url => "http://localhost:3001/set-cookie",
        :cookiefile => "",
        :cookiejar => path
      )
      writer.perform
      writer.cleanup

      expect(File.read(path)).to include("name\tvalue")

      reader = Ethon::Easy.new(
        :url => "http://localhost:3001/",
        :cookiefile => path
      )
      reader.perform

      expect(JSON.parse(reader.response_body)["HTTP_COOKIE"]).to eq("name=value")
    ensure
      reader.cleanup if reader
    end
  end

  it "sends a raw cookie header" do
    easy = Ethon::Easy.new(:url => "http://localhost:3001/", :cookie => "name=value")
    easy.perform

    expect(JSON.parse(easy.response_body)["HTTP_COOKIE"]).to eq("name=value")
  ensure
    easy.cleanup if easy
  end

  it "shares cookies between easy handles" do
    shared = Ethon::Curl::Share.new
    shared.share(:cookie)

    first = Ethon::Easy.new(
      :url => "http://localhost:3001/set-cookie",
      :cookiefile => "",
      :share => shared
    )
    first.perform

    second = Ethon::Easy.new(
      :url => "http://localhost:3001/",
      :cookiefile => "",
      :share => shared
    )
    second.perform

    expect(JSON.parse(second.response_body)["HTTP_COOKIE"]).to eq("name=value")
  ensure
    first.cleanup if first
    second.cleanup if second
    shared.free if shared
  end
end
