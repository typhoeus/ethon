# frozen_string_literal: true
require 'spec_helper'

describe "setting libcurl options" do
  let!(:easy) { Ethon::Easy.new }
  let(:multi) { Ethon::Multi.new }

  describe "return value handling" do
    it "returns :ok when libcurl accepts the option" do
      expect(Ethon::Curl.set_option(:timeout, 1, easy.handle)).to eq(:ok)
    end

    it "raises UnsupportedOption when libcurl does not know the option" do
      allow(Ethon::Curl).to receive(:easy_setopt).and_return(:unknown_option)

      expect { Ethon::Curl.set_option(:tcp_keepcnt, 1, easy.handle) }.
        to raise_error(Ethon::Errors::UnsupportedOption, /does not support the option: tcp_keepcnt/)
    end

    it "raises SetOption when libcurl rejects the value" do
      allow(Ethon::Curl).to receive(:easy_setopt).and_return(:unsupported_protocol)

      expect { Ethon::Curl.set_option(:http_version, :httpv3, easy.handle) }.
        to raise_error(Ethon::Errors::SetOption, /http_version.*unsupported_protocol/)
    end

    it "decodes multi errors with multi_strerror" do
      allow(Ethon::Curl).to receive(:multi_setopt).and_return(:out_of_memory)

      expect { Ethon::Curl.set_option(:maxconnects, 1, multi.handle, :multi) }.
        to raise_error(Ethon::Errors::SetOption, /maxconnects.*Out of memory/)
    end

    it "raises for a real unsupported option on the loaded libcurl" do
      skip "curl_easy_option_by_id is unavailable" unless Ethon::Curl.respond_to?(:easy_option_by_id)

      # Pick an option Ethon knows but the runtime does not. This is the older
      # libcurl case: before this check the option was silently ignored.
      name = Ethon::Curl.easy_options(nil).keys.find do |option|
        [:int, :bool, :string, :enum, :bitmask, :off_t, :time, :none].include?(
          Ethon::Curl.easy_options(nil)[option][:type]
        ) && !Ethon::Curl.supports_option?(option)
      end
      skip "the loaded libcurl supports every option Ethon knows" unless name

      value = Ethon::Curl.easy_options(nil)[name][:type] == :string ? "x" : 1

      expect { easy.public_send("#{name}=", value) }.
        to raise_error(Ethon::Errors::UnsupportedOption)
    end
  end
end
