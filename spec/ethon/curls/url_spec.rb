# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::UrlPart do
  it "maps the parts" do
    expect(described_class[:url]).to eq(0)
    expect(described_class[:scheme]).to eq(1)
    expect(described_class[:host]).to eq(5)
    expect(described_class[:zoneid]).to eq(10)
  end
end

describe Ethon::Curl::UrlCode do
  it "maps the codes" do
    expect(described_class[:ok]).to eq(0)
    expect(described_class[:bad_handle]).to eq(1)
    expect(described_class[:unsupported_scheme]).to eq(5)
    expect(described_class[:too_large]).to eq(31)
    expect(described_class[:last]).to eq(32)
  end
end

describe Ethon::Curl::UrlFlags do
  it "maps the flags" do
    expect(described_class[:default_port]).to eq(1 << 0)
    expect(described_class[:default_scheme]).to eq(1 << 2)
    expect(described_class[:urlencode]).to eq(1 << 7)
    expect(described_class[:puny2idn]).to eq(1 << 13)
  end
end

describe Ethon::Curl::Url do
  let(:url) { described_class.new("https://user:pass@example.com:8080/a/b?c=d#e") }

  before do
    skip "curl_url is unavailable" unless Ethon::Curl.respond_to?(:url)
  end

  it "parses a URL" do
    expect(url.get(:scheme)).to eq("https")
    expect(url.get(:user)).to eq("user")
    expect(url.get(:password)).to eq("pass")
    expect(url.get(:host)).to eq("example.com")
    expect(url.get(:port)).to eq("8080")
    expect(url.get(:path)).to eq("/a/b")
    expect(url.get(:query)).to eq("c=d")
    expect(url.get(:fragment)).to eq("e")
  end

  it "returns the normalized URL" do
    expect(url.to_s).to eq("https://user:pass@example.com:8080/a/b?c=d#e")
  end

  it "sets a part" do
    url.set(:path, "/changed")

    expect(url.get(:path)).to eq("/changed")
    expect(url.to_s).to include("/changed")
  end

  it "accepts string part names" do
    expect(url.get("host")).to eq("example.com")
  end

  it "duplicates independently" do
    copy = url.dup
    copy.set(:path, "/copy")

    expect(url.get(:path)).to eq("/a/b")
    expect(copy.get(:path)).to eq("/copy")
  end

  it "copies an existing URL handle" do
    copy = described_class.new(url)
    copy.set(:path, "/wrapped")

    expect(url.get(:path)).to eq("/a/b")
    expect(copy.get(:path)).to eq("/wrapped")
  end

  it "rejects a URL handle created before fork" do
    allow(url).to receive(:check_pid!).and_raise(Ethon::Errors::ForkSafety.new)

    expect { described_class.new(url) }.to raise_error(Ethon::Errors::ForkSafety)
  end

  it "raises for missing parts" do
    url.set(:fragment, nil)

    expect { url.get(:fragment) }.to raise_error(Ethon::Errors::Url, /fragment/i)
  end

  it "raises for invalid URLs" do
    expect { url.set(:url, "http://[::1") }.
      to raise_error(Ethon::Errors::Url, /IPv6/i)
  end

  it "accepts URL flags" do
    value = described_class.new

    value.set(:url, "https://example.com/a b", Ethon::Curl::UrlFlags[:allow_space])

    expect(value.get(:path)).to eq("/a b")
  end

end

describe Ethon::Curl::Url, "when the URL API is unavailable" do
  it "raises a NotImplementedError" do
    allow(Ethon::Curl).to receive(:respond_to?).and_call_original
    allow(Ethon::Curl).to receive(:respond_to?).with(:url).and_return(false)

    expect { described_class.new }.to raise_error(NotImplementedError, /curl_url/)
  end
end
