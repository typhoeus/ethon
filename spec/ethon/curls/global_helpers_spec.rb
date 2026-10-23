# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::SslBackend do
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

  it "attaches curl_multi_get_handles when supported" do
    skip "curl_multi_get_handles unavailable" unless described_class.respond_to?(:multi_get_handles)

    expect(described_class).to respond_to(:multi_get_handles)
  end

  it "attaches curl_global_sslset when supported" do
    skip "curl_global_sslset unavailable" unless described_class.respond_to?(:global_sslset)

    expect(described_class).to respond_to(:global_sslset)
  end

  it "attaches curl_global_trace when supported" do
    skip "curl_global_trace unavailable" unless described_class.respond_to?(:global_trace)

    expect(described_class).to respond_to(:global_trace)
  end
end
