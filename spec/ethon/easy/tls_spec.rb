# frozen_string_literal: true
require 'spec_helper'

describe "TLS verification" do
  let(:easy) do
    Ethon::Easy.new(
      :url => "https://localhost:#{TEST_HTTPS_PORT}/",
      :noproxy => "*",
      :ssl_verifypeer => true,
      :ssl_verifyhost => 2
    )
  end

  after { easy.cleanup }

  it "accepts the test server when its certificate is trusted" do
    easy.cainfo = TEST_TLS_CA_FILE
    easy.perform

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(200)
  end

  it "rejects the test server when its certificate is not trusted" do
    easy.cainfo = TEST_TLS_OTHER_CA_FILE
    easy.perform

    expect(easy.return_code).to eq(:peer_failed_verification)
    expect(easy.response_code).to eq(0)
  end

  it "rejects a certificate for another hostname" do
    easy.url = "https://127.0.0.1:#{TEST_HTTPS_PORT}/"
    easy.cainfo = TEST_TLS_CA_FILE
    easy.perform

    expect(easy.return_code).to eq(:peer_failed_verification)
  end
end
