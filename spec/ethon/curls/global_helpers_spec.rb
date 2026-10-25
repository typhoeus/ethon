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

describe "Ethon::Curl::SslSetCode" do
  let(:described_class) { Ethon::Curl::SslSetCode }

  it "maps the return codes" do
    expect(described_class[:ok]).to eq(0)
    expect(described_class[:unknown_backend]).to eq(1)
    expect(described_class[:too_late]).to eq(2)
    expect(described_class[:no_backends]).to eq(3)
  end
end

describe Ethon::Curl do
  it "attaches curl_multi_assign" do
    expect(described_class).to respond_to(:multi_assign)
  end

  it "decodes curl_global_sslset with CURLsslset values" do
    skip "curl_global_sslset is unavailable" unless described_class.respond_to?(:global_sslset)
    function = described_class.attached_functions[:global_sslset]
    skip "return type introspection is unavailable" unless function.respond_to?(:return_type)

    expect(function.return_type.from_native(1, nil)).to eq(:unknown_backend)
    expect(function.return_type.from_native(2, nil)).to eq(:too_late)
  end
end
