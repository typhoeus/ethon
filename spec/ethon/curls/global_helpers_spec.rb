# frozen_string_literal: true
require 'spec_helper'

describe "Ethon::Curl::SslBackend" do
  let(:described_class) { Ethon::Curl::SslBackend }

  it "maps the backends" do
    expect(described_class[:none]).to eq(0)
    expect(described_class[:openssl]).to eq(1)
    expect(described_class[:schannel]).to eq(8)
    expect(described_class[:rustls]).to eq(14)
  end
end

describe Ethon::Curl do
  it "attaches curl_multi_assign" do
    expect(described_class).to respond_to(:multi_assign)
  end
end
