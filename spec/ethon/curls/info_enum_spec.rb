# frozen_string_literal: true
require 'spec_helper'

describe "Ethon::Curl::Info" do
  let(:described_class) { Ethon::Curl::Info }

  it "maps last to CURLINFO_LASTONE" do
    expect(described_class[:last]).to eq(71)
  end

  it "keeps local_port correct" do
    expect(described_class[:local_port]).to eq(0x200000 + 42)
  end

  it "maps the newer off_t infos" do
    expect(described_class[:posttransfer_time_t]).to eq(0x600000 + 67)
    expect(described_class[:earlydata_sent_t]).to eq(0x600000 + 68)
    expect(described_class[:size_delivered]).to eq(0x600000 + 71)
  end

  it "maps the newer long infos" do
    expect(described_class[:httpauth_used]).to eq(0x200000 + 69)
    expect(described_class[:proxyauth_used]).to eq(0x200000 + 70)
  end
end
