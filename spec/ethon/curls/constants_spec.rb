# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl do
  describe "feature flags" do
    {
      :VERSION_KERBEROS5 => 1 << 18,
      :VERSION_UNIX_SOCKETS => 1 << 19,
      :VERSION_PSL => 1 << 20,
      :VERSION_HTTPS_PROXY => 1 << 21,
      :VERSION_MULTI_SSL => 1 << 22,
      :VERSION_BROTLI => 1 << 23,
      :VERSION_ALTSVC => 1 << 24,
      :VERSION_HTTP3 => 1 << 25,
      :VERSION_ZSTD => 1 << 26,
      :VERSION_UNICODE => 1 << 27,
      :VERSION_HSTS => 1 << 28,
      :VERSION_GSASL => 1 << 29,
      :VERSION_THREADSAFE => 1 << 30
    }.each do |name, value|
      it "maps #{name} to #{value}" do
        expect(described_class.const_get(name)).to eq(value)
      end
    end
  end

  describe "socket constants" do
    it "uses -1 for curl_socket_t on Unix" do
      skip "Windows uses SOCKET" if described_class.windows?

      expect(described_class::SOCKET_BAD).to eq(-1)
      expect(described_class::SOCKET_TIMEOUT).to eq(-1)
    end
  end
end
