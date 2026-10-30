# frozen_string_literal: true
require 'spec_helper'

describe "modern libcurl informations" do
  let(:easy) do
    Ethon::Easy.new(:url => "http://localhost:3001/").tap(&:perform)
  end

  it "exposes the request scheme" do
    expect(easy.scheme).to match(/\Ahttp\z/i)
  end

  it "exposes the HTTP version" do
    expect(easy.http_version).to be_a(Integer)
  end

  it "exposes the effective method" do
    expect(easy.effective_method).to eq("GET")
  end

  it "exposes whether a proxy was used" do
    expect([nil, 0, 1]).to include(easy.used_proxy)
  end

  it "exposes 64-bit timings" do
    expect(easy.total_time_t).to be_a(Integer)
    expect(easy.namelookup_time_t).to be_a(Integer)
    expect(easy.connect_time_t).to be_a(Integer)
    expect(easy.pretransfer_time_t).to be_a(Integer)
    expect(easy.starttransfer_time_t).to be_a(Integer)
    expect(easy.redirect_time_t).to be_a(Integer)
    expect(easy.appconnect_time_t).to be_a(Integer)
  end

  it "exposes 64-bit transfer sizes" do
    expect(easy.size_download_t).to eq(easy.response_body.bytesize)
    expect(easy.size_upload_t).to be_a(Integer)
  end

  it "exposes connection identifiers" do
    expect(easy.conn_id.nil? || easy.conn_id.is_a?(Integer)).to be(true)
    expect(easy.xfer_id.nil? || easy.xfer_id.is_a?(Integer)).to be(true)
    expect(easy.queue_time_t.nil? || easy.queue_time_t.is_a?(Integer)).to be(true)
  end

  it "exposes every non-pointer information" do
    Ethon::Easy::Informations::AVAILABLE_INFORMATIONS.each do |name, type|
      expect(easy).to respond_to(name)
      expect(easy.mirror).to respond_to(name) unless type == :ptr
    end
  end

  it "exposes the connection addresses and ports" do
    expect(easy.local_ip).to match(/::1|127\.0\.0\.1/)
    expect(easy.local_port).to be > 0
    expect(easy.primary_port).to eq(3001)
    expect(easy.ssl_verifyresult).to eq(0)
  end

  it "exposes connection and transfer metadata" do
    expect(easy.num_connects).to be >= 1
    expect(easy.header_size).to be > 0
    expect(easy.os_errno).to eq(0)
    expect(easy.http_connectcode).to eq(0)
    expect(easy.content_type).to be_a(String)
    expect(easy.content_length_download).to eq(easy.response_body.bytesize)
  end

  it "exposes the active socket" do
    expect(easy.activesocket).to be_a(Integer)
  end

  it "returns nil for infos that do not apply" do
    expect(easy.tls_ssl_ptr.nil? || easy.tls_ssl_ptr.is_a?(FFI::Pointer)).to be(true)
    expect([nil, 0]).to include(easy.retry_after)
    expect(easy.referer).to be_nil
  end

  it "includes the new values in the mirror" do
    expect(easy.mirror.options).to include(
      :http_version, :scheme, :effective_method, :conn_id, :xfer_id,
      :total_time_t, :size_download_t, :activesocket, :primary_port,
      :local_ip, :ssl_verifyresult
    )
  end

  it "keeps raw pointers out of the mirror" do
    expect(easy.mirror.options).not_to have_key(:tls_ssl_ptr)
    expect(easy.tls_ssl_ptr.nil? || easy.tls_ssl_ptr.is_a?(FFI::Pointer)).to be(true)
  end

  it "can be marshaled like a cached response" do
    copy = Marshal.load(Marshal.dump(easy.mirror))

    expect(copy.options).not_to have_key(:tls_ssl_ptr)
    expect(copy.options[:response_code]).to eq(200)
  end
end
