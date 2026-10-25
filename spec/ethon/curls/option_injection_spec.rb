# frozen_string_literal: true
require 'spec_helper'
require 'socket'

describe "line-based libcurl options" do
  let(:easy) { Ethon::Easy.new }

  # These option values end up in a request line, a protocol header, or a
  # protocol command. libcurl does not escape them, so CR and LF could add
  # attacker-controlled lines to the request.
  line_based_options = [
    :accept_encoding,
    :cookie,
    :customrequest,
    :encoding,
    :ftp_account,
    :ftp_alternative_to_user,
    :haproxy_client_ip,
    :krblevel,
    :login_options,
    :mail_auth,
    :mail_from,
    :range,
    :referer,
    :request_target,
    :rtsp_session_id,
    :rtsp_stream_uri,
    :rtsp_transport,
    :useragent,
    :xoauth2_bearer
  ]

  line_based_options.each do |option|
    describe "##{option}=" do
      ["\r", "\n", "\r\n"].each do |newline|
        it "rejects #{newline.inspect} before calling libcurl" do
          easy
          expect(Ethon::Curl).not_to receive(:easy_setopt)

          expect { easy.public_send("#{option}=", "value#{newline}X-Injected: yes") }.
            to raise_error(Ethon::Errors::InvalidValue, /#{option}/)
        end
      end

      it "accepts an ordinary value" do
        # CURLOPT_HAPROXY_CLIENT_IP was added in libcurl 8.2.0.
        skip "haproxy_client_ip requires libcurl 8.2.0" if
          option == :haproxy_client_ip && !Ethon::Curl.version_at_least?("8.2.0")
        # libcurl removed the option in 8.17.0 and now reports not_built_in.
        skip "krblevel was removed in libcurl 8.17.0" if
          option == :krblevel && Ethon::Curl.version_at_least?("8.17.0")

        expect { easy.public_send("#{option}=", "ordinary") }.not_to raise_error
      end
    end
  end

  it "rejects CR/LF through the low-level setter as well" do
    easy

    expect { Ethon::Curl.set_option(:useragent, "agent\r\nX-Injected: yes", easy.handle) }.
      to raise_error(Ethon::Errors::InvalidValue, /useragent/)
  end

  it "rejects CR/LF through option aliases" do
    easy
    expect(Ethon::Curl).not_to receive(:easy_setopt)

    expect { easy.encoding = "gzip\nX-Injected: yes" }.
      to raise_error(Ethon::Errors::InvalidValue, /encoding/)
  end

  describe "the URL" do
    it "rejects CR and LF before libcurl receives them" do
      expect { easy.url = "http://localhost/\r\nX-Injected: yes" }.
        to raise_error(Ethon::Errors::InvalidValue, /url/)

      expect { Ethon::Curl.set_option(:url, "http://localhost/\n", easy.handle) }.
        to raise_error(Ethon::Errors::InvalidValue, /url/)
    end

    it "keeps the previous URL when a new one is rejected" do
      easy.url = "http://localhost/"

      expect { easy.url = "http://localhost/?a=1\r\nX-Injected: yes" }.
        to raise_error(Ethon::Errors::InvalidValue, /url/)

      expect(easy.url).to eq("http://localhost/")
      expect(easy.log_inspect).not_to include("X-Injected")
    end

    it "still accepts percent-encoded line breaks" do
      expect { easy.url = "http://localhost/?a=1%0D%0AX-Injected:%20yes" }.
        not_to raise_error
    end
  end

  it "rejects whitespace in the HAProxy client IP" do
    easy
    expect(Ethon::Curl).not_to receive(:easy_setopt)

    # The value is a single field in the space-separated PROXY protocol line.
    [" ", "\t", "\v", "\f"].each do |space|
      expect { easy.haproxy_client_ip = "1.2.3.4#{space}5.6.7.8" }.
        to raise_error(Ethon::Errors::InvalidValue, /haproxy_client_ip/)
    end
  end

  it "still allows CR/LF in request bodies" do
    easy

    expect { easy.postfields = "line one\r\nline two" }.not_to raise_error
  end

  it "still allows CR/LF in credentials" do
    easy

    expect { easy.userpwd = "user:pa\r\nss" }.not_to raise_error
  end

  describe "an HTTP request" do
    # Capture the bytes libcurl actually writes without depending on the test
    # web server, which may normalize malformed requests.
    def with_raw_server
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]
      request = nil
      thread = Thread.new do
        socket = server.accept
        request = socket.readpartial(4096)
      ensure
        if socket
          socket.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok")
          socket.close
        end
      end

      yield port
      raise "raw server timed out" unless thread.join(5)

      request
    ensure
      server.close if server && !server.closed?
      thread.join(1) if thread
    end

    it "sends an ordinary custom request method unchanged" do
      request = with_raw_server do |port|
        easy.http_request("http://127.0.0.1:#{port}/", "purge")

        expect(easy.perform).to eq(:ok)
      end

      expect(request).to start_with("PURGE / HTTP/1.1\r\n")
    end

    it "still sends ordinary header option values" do
      request = with_raw_server do |port|
        easy.url = "http://127.0.0.1:#{port}/"
        easy.useragent = "ethon-test"
        easy.referer = "http://example.com/"
        easy.accept_encoding = "gzip"

        expect(easy.perform).to eq(:ok)
      end

      expect(request).to include("User-Agent: ethon-test\r\n")
      expect(request).to include("Referer: http://example.com/\r\n")
      expect(request).to include("Accept-Encoding: gzip\r\n")
    end
  end
end
