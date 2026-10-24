# frozen_string_literal: true
require 'spec_helper'

describe "libcurl symbolic option values" do
  let(:easy) { Ethon::Easy.new }

  def expect_long(value)
    expect(Ethon::Curl).to receive(:easy_setopt).
      with(easy.handle, anything, :long, value).and_return(:ok)
  end

  it "supports CURLPROXY_HTTPS2" do
    expect_long(3)
    easy.proxytype = :https2
  end

  it "keeps CURLPROXY_SOCKS4 at 4" do
    expect_long(4)
    easy.proxytype = :socks4
  end

  it "supports CURL_HTTP_VERSION_3" do
    expect_long(30)
    easy.http_version = :httpv3
  end

  it "supports CURL_HTTP_VERSION_3ONLY" do
    expect_long(31)
    easy.http_version = :httpv3only
  end

  it "supports CURLAUTH_BEARER" do
    expect_long(64)
    easy.httpauth = :bearer
  end

  it "supports CURLAUTH_AWS_SIGV4" do
    expect_long(128)
    easy.httpauth = :aws_sigv4
  end

  it "supports the negotiate alias" do
    expect_long(4)
    easy.httpauth = :negotiate
  end

  it "supports the newer protocol bits" do
    expect_long(1 << 26)
    easy.protocols = :smb

    expect_long(1 << 27)
    easy.protocols = :smbs

    expect_long(1 << 28)
    easy.protocols = :mqtt

    expect_long(1 << 29)
    easy.protocols = :gophers
  end

  it "supports the newer SSL option bits" do
    {
      :allow_beast => 1 << 0,
      :no_revoke => 1 << 1,
      :no_partialchain => 1 << 2,
      :revoke_best_effort => 1 << 3,
      :native_ca => 1 << 4,
      :auto_client_cert => 1 << 5
    }.each do |name, value|
      expect_long(value)
      easy.ssl_options = name
    end
  end

  it "combines SSL option bits" do
    expect_long((1 << 1) | (1 << 4))
    easy.ssl_options = [:no_revoke, :native_ca]
  end

  it "supports CURLSSH_AUTH_GSSAPI" do
    expect_long(1 << 5)
    easy.ssh_auth_types = :gssapi
  end

  it "does not expose the fake khstat option" do
    expect(Ethon::Curl.easy_options(nil)).not_to have_key(:khstat)
    expect(easy).not_to respond_to(:khstat=)
    expect(Ethon::Curl::EasyOption[:khstat]).to be_nil
  end

  describe "numeric ranges" do
    let(:long_limit) { 1 << (FFI.type_size(:long) * 8 - 1) }

    it "accepts the signed long limits" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :long, anything).twice.and_return(:ok)

      easy.timeout = long_limit - 1
      easy.timeout = -long_limit
    end

    it "rejects values that overflow a signed long" do
      expect { easy.timeout = long_limit }.
        to raise_error(Ethon::Errors::InvalidValue)
    end

    it "rejects values below a signed long" do
      expect { easy.timeout = -long_limit - 1 }.
        to raise_error(Ethon::Errors::InvalidValue)
    end

    it "rejects values that overflow curl_off_t" do
      expect { easy.timevalue_large = 2**63 }.
        to raise_error(Ethon::Errors::InvalidValue)
    end
  end
end
