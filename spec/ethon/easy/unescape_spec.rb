# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy do
  let(:easy) { Ethon::Easy.new }

  describe "#unescape" do
    it "unescapes a value" do
      expect(easy.unescape("a%20b")).to eq("a b")
    end

    it "round trips with escape" do
      value = "a b+c/ま"

      expect(easy.unescape(easy.escape(value))).to eq(value)
    end

    it "preserves embedded null bytes" do
      expect(easy.unescape("a%00b")).to eq("a\0b")
    end

    it "raises when libcurl cannot allocate the result" do
      allow(Ethon::Curl).to receive(:easy_unescape).and_return(FFI::Pointer::NULL)

      expect { easy.unescape("a") }.to raise_error(NoMemoryError, "curl_easy_unescape failed")
    end
  end
end
