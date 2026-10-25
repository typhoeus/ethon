# frozen_string_literal: true
require 'spec_helper'

describe "Ethon::Curl::UrlPart" do
  let(:described_class) { Ethon::Curl::UrlPart }

  it "maps the parts" do
    expect(described_class[:url]).to eq(0)
    expect(described_class[:scheme]).to eq(1)
    expect(described_class[:host]).to eq(5)
    expect(described_class[:zoneid]).to eq(10)
  end
end

describe "Ethon::Curl::UrlCode" do
  let(:described_class) { Ethon::Curl::UrlCode }

  it "maps the codes" do
    expect(described_class[:ok]).to eq(0)
    expect(described_class[:bad_handle]).to eq(1)
    expect(described_class[:unsupported_scheme]).to eq(5)
    expect(described_class[:too_large]).to eq(31)
    expect(described_class[:backslash]).to eq(32)
    expect(described_class[:last]).to eq(33)
  end
end

describe "Ethon::Curl::UrlFlags" do
  let(:described_class) { Ethon::Curl::UrlFlags }

  it "maps the flags" do
    expect(described_class[:default_port]).to eq(1 << 0)
    expect(described_class[:default_scheme]).to eq(1 << 2)
    expect(described_class[:urlencode]).to eq(1 << 7)
    expect(described_class[:puny2idn]).to eq(1 << 13)
    expect(described_class[:get_empty]).to eq(1 << 14)
    expect(described_class[:no_guess_scheme]).to eq(1 << 15)
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

  it "copies a partial URL handle instead of parsing its string form" do
    partial = described_class.new
    partial.set(:scheme, "https")
    partial.set(:host, "example.com")
    partial.set(:path, "/partial")

    copy = described_class.new(partial)

    expect(copy.get(:scheme)).to eq("https")
    expect(copy.get(:host)).to eq("example.com")
    expect(copy.get(:path)).to eq("/partial")
  end

  it "copies a handle that does not have a complete URL yet" do
    partial = described_class.new
    partial.set(:path, "/only")

    copy = described_class.new(partial)

    expect(copy.get(:path)).to eq("/only")
  end

  it "does not re-parse a URL handle" do
    url
    expect(Ethon::Curl).not_to receive(:url_set)

    described_class.new(url)
  end

  it "applies CURLU flags only when parsing a string" do
    expect {
      described_class.new(url, :default_port)
    }.to raise_error(ArgumentError, /flags cannot be applied/)

    expect { described_class.new(url, 0) }.not_to raise_error
    expect { described_class.new(url, []) }.not_to raise_error
    expect { described_class.new(url, nil) }.not_to raise_error
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

  it "accepts a nil value to clear a part" do
    url.set(:query, nil)

    expect { url.get(:query) }.to raise_error(Ethon::Errors::Url)
  end

  it "accepts a flag name or an array of flag names" do
    value = described_class.new

    value.set(:url, "https://example.com/a b", [:allow_space])
    expect(value.get(:path)).to eq("/a b")

    value.set(:path, "/c d", :allow_space)
    expect(value.get(:path)).to eq("/c d")
  end

  it "rejects an unknown flag name" do
    url
    expect(Ethon::Curl).not_to receive(:url_set)

    expect { url.set(:host, "example.org", :bogus) }.
      to raise_error(Ethon::Errors::InvalidValue, /url_flags/)
  end

  it "rejects an unknown flag name when reading" do
    url
    expect(Ethon::Curl).not_to receive(:url_get)

    expect { url.get(:host, :bogus) }.
      to raise_error(Ethon::Errors::InvalidValue, /url_flags/)
  end

  it "coerces non-string values" do
    url.set(:fragment, :anchor)

    expect(url.get(:fragment)).to eq("anchor")
  end

  it "rejects an unknown part name" do
    url
    expect(Ethon::Curl).not_to receive(:url_set)

    expect { url.set(:bogus, "value") }.
      to raise_error(Ethon::Errors::InvalidValue, /url_part/)
  end

  it "rejects an unknown part name when reading" do
    url
    expect(Ethon::Curl).not_to receive(:url_get)

    expect { url.get(:bogus) }.
      to raise_error(Ethon::Errors::InvalidValue, /url_part/)
  end

  it "accepts an enum value as the part name" do
    url.set(Ethon::Curl::UrlPart[:host], "example.org")

    expect(url.get(:host)).to eq("example.org")
  end

  it "rejects an unknown enum value as the part name" do
    url
    expect(Ethon::Curl).not_to receive(:url_set)

    expect { url.set(99, "value") }.
      to raise_error(Ethon::Errors::InvalidValue, /url_part/)
  end

  it "rejects a part name that is not a string, symbol, or enum value" do
    expect { url.set(Object.new, "value") }.
      to raise_error(Ethon::Errors::InvalidValue, /url_part/)
  end

  it "rejects a value containing a NUL byte" do
    url
    expect(Ethon::Curl).not_to receive(:url_set)

    expect { url.set(:url, "https://example.com/\0truncated") }.
      to raise_error(Ethon::Errors::InvalidValue, /url_value/)
    expect(url.get(:host)).to eq("example.com")
  end

  it "rejects a NUL byte in the initial URL" do
    expect { described_class.new("https://example.com/\0truncated") }.
      to raise_error(Ethon::Errors::InvalidValue, /url_value/)
  end

  it "releases the native handle when the initial URL is rejected" do
    pointer = nil
    allow(Ethon::Curl).to receive(:url).and_wrap_original do |original|
      pointer = original.call
    end

    expect { described_class.new("https://example.com/\0truncated") }.
      to raise_error(Ethon::Errors::InvalidValue)
    expect(Ethon::Curl::OwnedPointer.owners).not_to have_key(pointer.address)
  end

  describe "request injection through URL parts" do
    let(:base) { described_class.new }

    before do
      base.set(:scheme, "https")
      base.set(:host, "example.com")
      base.set(:path, "/")
    end

    [:url, :path, :query, :fragment, :user, :password, :options].each do |part|
      ["\r", "\n", "\r\n"].each do |newline|
        it "rejects #{newline.inspect} in #{part}" do
          expect {
            base.set(part, "value#{newline}X-Injected: yes")
          }.to raise_error(Ethon::Errors::InvalidValue, /url_value/)
        end
      end
    end

    it "rejects a request line injected through the initial URL" do
      expect { described_class.new("https://example.com/valid\r\nX-Injected: yes") }.
        to raise_error(Ethon::Errors::InvalidValue, /url_value/)
    end

    it "does not let URLENCODE bypass the check" do
      expect { base.set(:query, "a=1\r\nX-Injected: yes", :urlencode) }.
        to raise_error(Ethon::Errors::InvalidValue, /url_value/)
    end

    it "still accepts percent-encoded line breaks" do
      expect { base.set(:query, "a=1%0D%0AX-Injected:%20yes") }.
        not_to raise_error

      expect(base.to_s).to include("a=1%0d%0aX-Injected:%20yes")
    end

    it "does not change the URL when a part is rejected" do
      expect { base.set(:path, "/changed\r\n") }.
        to raise_error(Ethon::Errors::InvalidValue)

      expect(base.get(:path)).to eq("/")
    end
  end

end

describe Ethon::Easy, "with CURLOPT_CURLU" do
  let(:easy) { Ethon::Easy.new }
  let(:url) { Ethon::Curl::Url.new("http://localhost:3001/") }

  before do
    skip "curl_url is unavailable" unless Ethon::Curl.respond_to?(:url)
  end

  it "retains the URL handle" do
    easy.curlu = url

    expect(easy.curlu).to be(url)
    expect(easy.instance_variable_get(:@curlu)).to be(url)
  end

  it "uses the URL handle for the request" do
    easy.curlu = url

    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
  end

  it "clears the URL handle on reset" do
    easy.curlu = url

    easy.reset

    expect(easy.curlu).to be_nil
  end

  it "clears the URL handle when a string url is set" do
    easy.curlu = url
    easy.url = "http://localhost:3001/second"

    expect(easy.curlu).to be_nil
    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).to include('"PATH_INFO":"/second"')
  end

  it "clears the string url when a URL handle is set" do
    easy.url = "http://localhost:3001/first"
    easy.curlu = url

    expect(easy.url).to be_nil
    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).to include('"PATH_INFO":"/"')
  end

  it "keeps the URL handle when the replacement cannot be converted" do
    easy.curlu = url
    invalid = Object.new
    def invalid.to_s
      raise ArgumentError, "cannot convert"
    end

    expect { easy.url = invalid }.to raise_error(ArgumentError, /convert/)
    expect(easy.curlu).to be(url)
    expect(easy.perform).to eq(:ok)
  end

  it "keeps the URL handle when the replacement string is rejected" do
    easy.curlu = url

    expect { easy.url = "http://localhost:3001/\0" }.
      to raise_error(Ethon::Errors::InvalidValue, /url/)

    expect(easy.curlu).to be(url)
    expect(easy.url).to be_nil
    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).to include('"PATH_INFO":"/"')
  end

  it "rejects a URL handle created before fork" do
    allow(url).to receive(:check_pid!).and_raise(Ethon::Errors::ForkSafety.new)

    expect { easy.curlu = url }.to raise_error(Ethon::Errors::ForkSafety)
  end

  it "rejects another owned pointer type" do
    easy
    list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))
    expect(Ethon::Curl).not_to receive(:set_option)

    expect { easy.curlu = list }.
      to raise_error(TypeError, /Ethon::Curl::Url/)
    expect(easy.curlu).to be_nil
  ensure
    list.free if list
  end

  it "rejects a raw pointer" do
    list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))

    expect { easy.curlu = FFI::Pointer.new(list.address) }.
      to raise_error(TypeError, /Ethon::Curl::Url/)
  ensure
    list.free if list
  end

  it "keeps the URL handle when the replacement is rejected" do
    easy.curlu = url

    expect { easy.curlu = "http://localhost:3001/" }.
      to raise_error(TypeError, /Ethon::Curl::Url/)
    expect(easy.curlu).to be(url)
  end
end

describe Ethon::Curl::Url, "when the URL API is unavailable" do
  it "raises a NotImplementedError" do
    allow(Ethon::Curl).to receive(:respond_to?).and_call_original
    allow(Ethon::Curl).to receive(:respond_to?).with(:url).and_return(false)

    expect { described_class.new }.to raise_error(NotImplementedError, /curl_url/)
  end
end
