# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::HeadersApi do
  let(:easy) do
    Ethon::Easy.new(:url => "http://localhost:3001/multiple-headers").tap(&:perform)
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
    end

    it "raises for missing headers" do
      expect { easy.header("X-Missing") }.
        to raise_error(Ethon::Errors::Header, /missing/)
    end

    it "raises when the header API is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:easy_header).and_return(false)

      expect { easy.header("Content-Type") }.
        to raise_error(NotImplementedError, /curl_easy_header/)
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

    it "raises when the header API is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:easy_nextheader).and_return(false)

      expect { easy.each_header }.
        to raise_error(NotImplementedError, /curl_easy_nextheader/)
    end
  end
end
