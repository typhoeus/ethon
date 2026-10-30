# frozen_string_literal: true
require 'spec_helper'

describe "proxying" do
  let(:credentials) { "#{LocalProxyServer::USERNAME}:#{LocalProxyServer::PASSWORD}" }
  let(:easy) do
    Ethon::Easy.new(
      :url => "http://localhost:3001/",
      :proxy => "http://localhost:#{TEST_PROXY_PORT}",
      :noproxy => ""
    )
  end

  after { easy.cleanup }

  it "routes a request through an authenticated proxy" do
    easy.proxyuserpwd = credentials
    easy.perform

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(200)
    expect(easy.proxy_error).to eq(0)
  end

  it "reports when a proxy was used" do
    easy.proxyuserpwd = credentials
    easy.perform

    skip "CURLINFO_USED_PROXY is unavailable in this libcurl" if easy.used_proxy.nil?

    expect(easy.used_proxy).to eq(1)
  end

  it "returns the proxy authentication challenge without credentials" do
    easy.perform

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(407)
  end

  it "tunnels HTTPS through the proxy" do
    easy.url = "https://localhost:#{TEST_HTTPS_PORT}/"
    easy.ssl_verifypeer = false
    easy.proxyuserpwd = credentials
    easy.perform

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(200)
  end
end
