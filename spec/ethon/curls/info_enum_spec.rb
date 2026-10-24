# frozen_string_literal: true
require 'spec_helper'

describe "Ethon::Curl::Info" do
  let(:described_class) { Ethon::Curl::Info }

  it "maps last to CURLINFO_LASTONE" do
    expect(described_class[:last]).to eq(66)
  end

  it "keeps local_port correct" do
    expect(described_class[:local_port]).to eq(0x200000 + 42)
  end
end
