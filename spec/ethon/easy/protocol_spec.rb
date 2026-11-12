# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'tmpdir'

describe "protocol behaviour" do
  def perform(options)
    easy = Ethon::Easy.new(options)
    easy.perform
    easy
  end

  def response_env(easy)
    JSON.parse(easy.response_body)
  end

  it "resolves to IPv4 when requested" do
    easy = perform(:url => "http://localhost:3001/", :ipresolve => :v4)

    expect(easy.return_code).to eq(:ok)
    expect(easy.primary_ip).to eq("127.0.0.1")
  ensure
    easy.cleanup if easy
  end

  it "uses a custom resolve entry instead of DNS" do
    resolve = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["example.test:3001:127.0.0.1"]))
    easy = perform(
      :url => "http://example.test:3001/",
      :noproxy => "*",
      :resolve => resolve
    )

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(200)
    expect(easy.primary_ip).to eq("127.0.0.1")
    expect(response_env(easy)["HTTP_HOST"]).to eq("example.test:3001")
  ensure
    easy.cleanup if easy
  end

  it "requests HTTP/1.0 when configured" do
    easy = perform(:url => "http://localhost:3001/", :http_version => :httpv1_0, :verbose => true)

    expect(easy.return_code).to eq(:ok)
    expect(easy.debug_info.header_out.join).to include("GET / HTTP/1.0")
  ensure
    easy.cleanup if easy
  end

  it "requests HTTP/1.1 when configured" do
    easy = perform(:url => "http://localhost:3001/", :http_version => :httpv1_1, :verbose => true)

    expect(easy.return_code).to eq(:ok)
    expect(easy.debug_info.header_out.join).to include("GET / HTTP/1.1")
  ensure
    easy.cleanup if easy
  end

  it "sends the referring URL when following a redirect" do
    easy = perform(
      :url => "http://localhost:3001/redirect",
      :followlocation => true,
      :autoreferer => true
    )

    expect(easy.return_code).to eq(:ok)
    expect(response_env(easy)["HTTP_REFERER"]).to eq("http://localhost:3001/redirect")
  ensure
    easy.cleanup if easy
  end

  it "requests a byte range" do
    easy = perform(:url => "http://localhost:3001/range", :range => "2-5")

    expect(easy.response_code).to eq(206)
    expect(easy.response_body).to eq("2345")
    expect(easy.response_headers).to include("Content-Range: bytes 2-5/10")
  ensure
    easy.cleanup if easy
  end

  it "resumes from an offset" do
    easy = perform(:url => "http://localhost:3001/range", :resume_from => 6)

    expect(easy.response_code).to eq(206)
    expect(easy.response_body).to eq("6789")
  ensure
    easy.cleanup if easy
  end

  it "returns 304 when the resource has not been modified since the condition" do
    easy = perform(
      :url => "http://localhost:3001/modified",
      :timecondition => :ifmodsince,
      :timevalue => Time.utc(2021, 1, 1).to_i
    )

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(304)
  ensure
    easy.cleanup if easy
  end

  it "returns the body when the resource was modified after the condition" do
    easy = perform(
      :url => "http://localhost:3001/modified",
      :timecondition => :ifmodsince,
      :timevalue => Time.utc(2019, 1, 1).to_i
    )

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(200)
    expect(easy.response_body).to eq("body")
  ensure
    easy.cleanup if easy
  end

  it "authenticates from a netrc file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "netrc")
      File.write(path, "machine localhost login username password password\n")

      easy = perform(
        :url => "http://localhost:3001/auth_basic/username/password",
        :netrc => :required,
        :netrc_file => path
      )

      expect(easy.return_code).to eq(:ok)
      expect(easy.response_code).to eq(200)
    ensure
      easy.cleanup if easy
    end
  end

  it "stops after connecting with connect_only" do
    easy = perform(:url => "http://localhost:3001/", :connect_only => true)

    expect(easy.return_code).to eq(:ok)
    expect(easy.response_code).to eq(0)
    expect(easy.response_body).to eq("")
  ensure
    easy.cleanup if easy
  end

  it "refuses a download larger than max_filesize" do
    easy = perform(:url => "http://localhost:3001/binary/1000", :maxfilesize => 100)

    expect(easy.return_code).to eq(:filesize_exceeded)
  ensure
    easy.cleanup if easy
  end
end
