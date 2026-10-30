# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy, "certinfo" do
  let(:easy) { Ethon::Easy.new }

  before do
    easy.url = "https://localhost:#{TEST_HTTPS_PORT}/"
    easy.ssl_verifypeer = false
    easy.ssl_verifyhost = 0
    easy.certinfo = true
  end

  after { easy.cleanup }

  it "returns the certificate chain of a TLS connection" do
    easy.perform

    expect(easy.return_code).to eq(:ok)
    expect(easy.certinfo).not_to be_empty
    expect(easy.certinfo.first).to include(a_string_starting_with("Subject:"))
  end

  it "keeps the chain on the mirror after the easy is reset" do
    mirror = nil
    easy.on_complete do |completed|
      # Reproduce the pooling handoff: the mirror is built before the handle
      # is reset, and the reset frees libcurl's certificate chain.
      mirror = completed.mirror
      completed.reset
    end

    easy.perform

    expect(easy.certinfo).to eq([])
    expect(mirror.certinfo).not_to be_empty
    expect(mirror.certinfo.first).to include(a_string_starting_with("Subject:"))
  end
end
