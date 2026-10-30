# frozen_string_literal: true
require 'spec_helper'

describe "mutual TLS" do
  let(:easy) do
    Ethon::Easy.new(
      :url => "https://localhost:#{TEST_MTLS_PORT}/",
      :noproxy => "*",
      :cainfo => TEST_MTLS_CA_FILE
    )
  end

  after { easy.cleanup }

  it "accepts a client certificate signed by the server's CA" do
    easy.sslcert = TEST_MTLS_CLIENT_CERT_FILE
    easy.sslkey = TEST_MTLS_CLIENT_KEY_FILE
    easy.perform

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(200)
  end

  it "rejects a client without a certificate" do
    easy.perform

    expect(easy.return_code).not_to eq(:ok)
    expect(easy.response_code).to eq(0)
  end
end
