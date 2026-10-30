# frozen_string_literal: true
require 'spec_helper'
require 'json'

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
end
