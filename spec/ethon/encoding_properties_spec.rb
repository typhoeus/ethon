# frozen_string_literal: true
require 'spec_helper'
require 'uri'

describe "encoding properties" do
  let(:easy) { Ethon::Easy.new }

  describe "#escape and #unescape" do
    it "round-trips arbitrary byte strings" do
      random = Random.new(20_261_024)

      100.times do
        value = random.bytes(random.rand(0..64))
        expect(easy.unescape(easy.escape(value))).to eq(value)
      end
    end

    it "percent-encodes every byte outside the unreserved set" do
      unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~".bytes

      (0..255).each do |byte|
        next if unreserved.include?(byte)

        expect(easy.escape(byte.chr.b)).to eq(format("%%%02X", byte))
      end
    end
  end

  describe "query parameters" do
    it "round-trip through standard URL decoding" do
      alphabet = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a +
        [" ", "+", "&", "=", "%", "?", "#", "/", "[", "]", "ü", "\0", "!", "~", "."]
      random = Random.new(7)

      30.times do
        value = Array.new(random.rand(0..20)) { alphabet.sample(random: random) }.join
        easy.http_request("http://localhost:3001/", :get, :params => { "key" => value })

        expect(URI.decode_www_form(URI(easy.url).query)).to eq([["key", value]])
      end
    end
  end
end
