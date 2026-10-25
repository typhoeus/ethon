# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::HeadersApi do
  let(:easy) do
    Ethon::Easy.new(:url => "http://localhost:3001/multiple-headers").tap(&:perform)
  end

  before do
    skip "curl_easy_header is unavailable" unless Ethon::Curl.respond_to?(:easy_header)
  end

  describe "#header" do
    it "returns a parsed header" do
      header = easy.header("Content-Type")

      expect(header).to be_a(Ethon::Curl::Header)
      expect(header.name).to eq("Content-Type")
      expect(header.value).to eq("text/plain")
      expect(header.amount).to be_a(Integer)
    end

    it "supports repeated headers by index" do
      expect(easy.header("Set-Cookie", 0).value).to eq("foo")
      expect(easy.header("Set-Cookie", 1).value).to eq("bar")
      expect(easy.header("Set-Cookie", 0).amount).to eq(2)
    end

    it "reports only the documented CURLH_* origin bits" do
      header = easy.header("Content-Type")

      expect(header.origin).to eq(Ethon::Curl::HeaderOrigin[:header])
      expect(header.origin & ~Ethon::Curl::HeaderOrigin[:header]).to eq(0)
    end

    it "raises for missing headers" do
      expect { easy.header("X-Missing") }.
        to raise_error(Ethon::Errors::Header, /missing/)
    end

    it "accepts an array of origins" do
      expect(easy.header("Content-Type", 0, [:header]).value).to eq("text/plain")
    end

    it "asks libcurl for the last request by default" do
      expect(Ethon::Curl).to receive(:easy_header).
        with(
          easy.handle,
          "Content-Type",
          0,
          Ethon::Curl::HeaderOrigin[:header],
          Ethon::Easy::HeadersApi::LAST_REQUEST,
          anything
        ).
        and_call_original

      expect(easy.header("Content-Type").value).to eq("text/plain")
    end

    it "accepts a symbol origin" do
      expect(easy.header("Content-Type", 0, :header).value).to eq("text/plain")
    end

    it "rejects an unknown origin" do
      expect { easy.header("Content-Type", 0, :not_an_origin) }.
        to raise_error(Ethon::Errors::InvalidValue, /header_origin/)
    end

  end

  describe "#each_header" do
    it "enumerates response headers" do
      headers = easy.each_header.to_a

      expect(headers).not_to be_empty
      expect(headers.map(&:name)).to include("Content-Type")
    end

    it "supports headers_list as an alias" do
      expect(easy.headers_list.to_a).not_to be_empty
    end

    it "accepts an array of origins" do
      expect(easy.each_header([:header]).to_a).not_to be_empty
    end

  end

  describe "request selection after following redirects" do
    let(:easy) do
      Ethon::Easy.new(
        :url => "http://localhost:3001/redirect_with_headers",
        :followlocation => true
      ).tap(&:perform)
    end

    def stage_values(headers = easy.each_header)
      headers.select { |header| header.name.casecmp?("X-Request-Stage") }.map(&:value)
    end

    it "reads the final response by default" do
      expect(easy.header("X-Request-Stage").value).to eq("target")
    end

    it "reads the first response when request 0 is passed explicitly" do
      expect(easy.header("X-Request-Stage", 0, :header, 0).value).to eq("redirect")
    end

    it "enumerates the final response by default" do
      expect(stage_values).to eq(["target"])
    end

    it "enumerates the first response when request 0 is passed explicitly" do
      expect(stage_values(easy.each_header(:header, 0))).to eq(["redirect"])
    end
  end
end

describe Ethon::Easy::HeadersApi, "when the header API is unavailable" do
  let(:easy) { Ethon::Easy.new }

  it "raises from #header" do
    allow(Ethon::Curl).to receive(:respond_to?).and_call_original
    allow(Ethon::Curl).to receive(:respond_to?).with(:easy_header).and_return(false)

    expect { easy.header("Content-Type") }.
      to raise_error(NotImplementedError, /curl_easy_header/)
  end

  it "raises from #each_header" do
    allow(Ethon::Curl).to receive(:respond_to?).and_call_original
    allow(Ethon::Curl).to receive(:respond_to?).with(:easy_nextheader).and_return(false)

    expect { easy.each_header }.
      to raise_error(NotImplementedError, /curl_easy_nextheader/)
  end
end
