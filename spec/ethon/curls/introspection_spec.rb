# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::HeaderCode do
  it "maps the codes" do
    expect(described_class[:ok]).to eq(0)
    expect(described_class[:missing]).to eq(2)
    expect(described_class[:bad_argument]).to eq(6)
    expect(described_class[:not_built_in]).to eq(7)
  end
end

describe Ethon::Curl::HeaderOrigin do
  it "maps the origin bits" do
    expect(described_class[:header]).to eq(1 << 0)
    expect(described_class[:trailer]).to eq(1 << 1)
    expect(described_class[:connect]).to eq(1 << 2)
    expect(described_class[:xx1]).to eq(1 << 3)
    expect(described_class[:pseudo]).to eq(1 << 4)
  end
end

describe Ethon::Curl::EasyType do
  it "maps the option types" do
    expect(described_class[:long]).to eq(0)
    expect(described_class[:off_t]).to eq(2)
    expect(described_class[:string]).to eq(4)
    expect(described_class[:function]).to eq(8)
  end
end

describe "libcurl option introspection" do
  it "looks up an option by name" do
    info = Ethon::Curl.easy_option("URL")

    expect(info.name).to eq("URL")
    expect(info.id).to eq(:url)
    expect(info.type).to eq(:string)
    expect(info.alias?).to be(false)
  end

  it "looks up an option by id" do
    expect(Ethon::Curl.option_by_id(10002).name).to eq("URL")
  end

  it "returns nil for unknown options" do
    expect(Ethon::Curl.easy_option("NOT_A_CURL_OPTION")).to be_nil
    expect(Ethon::Curl.option_by_id(999999)).to be_nil
  end

  it "enumerates options" do
    expect(Ethon::Curl.each_easy_option).to be_a(Enumerator)
    expect(Ethon::Curl.easy_option_list.map(&:name)).to include("URL")
  end
end

describe "libcurl version introspection" do
  it "lists protocols" do
    expect(Ethon::Curl.protocols).to include("http")
  end

  it "lists feature names when the runtime supports them" do
    info = Ethon::Curl.version_info_full
    skip "CURLVERSION_ELEVENTH unavailable" unless info

    expect(Ethon::Curl.feature_names).not_to be_empty
  end

  it "returns nil for an old version struct" do
    allow(Ethon::Curl).to receive(:version_info).and_return({ :curl_version => 3 })

    expect(Ethon::Curl.version_info_full).to be_nil
    expect(Ethon::Curl.feature_names).to eq([])
  end

  it "handles null pointer arrays" do
    expect(Ethon::Curl.string_array(nil)).to eq([])
    expect(Ethon::Curl.string_array(FFI::Pointer::NULL)).to eq([])
  end
end
