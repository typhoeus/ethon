# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Header do
  let(:easy) { Ethon::Easy.new }

  describe "#headers=" do
    let(:headers) { { 'User-Agent' => 'Ethon' } }

    it "sets header" do
      expect_any_instance_of(Ethon::Easy).to receive(:set_callbacks)
      expect(Ethon::Curl).to receive(:set_option)
      easy.headers = headers
    end

    context "when a value contains CRLF" do
      let(:headers) { { 'X-Test' => "1\r\nX-Injected: yes" } }

      it "rejects the header" do
        expect { easy.headers = headers }.
          to raise_error(Ethon::Errors::InvalidValue, /headers/)
      end
    end

    context "when a name contains CRLF" do
      let(:headers) { { "X-Test\r\nX-Injected" => "yes" } }

      it "rejects the header" do
        expect { easy.headers = headers }.
          to raise_error(Ethon::Errors::InvalidValue, /headers/)
      end
    end

    context "when a value contains a bare LF" do
      let(:headers) { { 'X-Test' => "1\nX-Injected: yes" } }

      it "rejects the header" do
        expect { easy.headers = headers }.
          to raise_error(Ethon::Errors::InvalidValue, /headers/)
      end
    end

    context "when requesting" do
      before do
        easy.headers = headers
        easy.url = "http://localhost:3001"
        easy.perform
      end

      it "sends" do
        expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon"')
      end

      context "when header value contains null byte" do
        let(:headers) { { 'User-Agent' => "Ethon\0" } }

        it "escapes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon\\\\0"')
        end
      end

      context "when header value has leading whitespace" do
        let(:headers) { { 'User-Agent' => " Ethon" } }

        it "removes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon"')
        end
      end

      context "when header value has traiing whitespace" do
        let(:headers) { { 'User-Agent' => "Ethon " } }

        it "removes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon"')
        end
      end

      context "when removing a default header" do
        let(:headers) { { 'Accept' => '' } }

        it "does not send the header" do
          expect(easy.response_body).not_to include('"HTTP_ACCEPT"')
        end
      end

      context "when sending an empty header" do
        let(:headers) { { 'X-Empty;' => '' } }

        it "sends the header with an empty value" do
          expect(easy.response_body).to include('"HTTP_X_EMPTY":""')
        end
      end
    end
  end

  describe "#compose_header" do
    it "has space in between" do
      expect(easy.compose_header('a', 'b')).to eq('a: b')
    end

    context "when value is a symbol" do
      it "works" do
        expect{ easy.compose_header('a', :b) }.to_not raise_error
      end
    end

    context "when value is empty" do
      it "composes a header that removes libcurl's default" do
        expect(easy.compose_header('Accept', '')).to eq('Accept: ')
      end

      it "composes a header that forces an empty value" do
        expect(easy.compose_header('X-Empty;', '')).to eq('X-Empty;')
      end
    end
  end

  describe "#header_list" do
    context "when no set_headers" do
      it "returns nil" do
        expect(easy.header_list).to eq(nil)
      end
    end

    context "when set_headers" do
      it "returns Slist to header list" do
        easy.headers = {'User-Agent' => 'Custom'}
        expect(easy.header_list).to be_a(Ethon::Curl::Slist)
      end
    end
  end

  describe "#request_headers" do
    it "returns an empty hash by default" do
      expect(easy.request_headers).to eq({})
    end

    it "returns the headers that were set" do
      headers = { 'User-Agent' => 'Ethon' }
      easy.headers = headers

      expect(easy.request_headers).to eq(headers)
    end

    it "can be set through request_headers=" do
      easy.request_headers = { 'X-Test' => 'yes' }

      expect(easy.request_headers).to eq('X-Test' => 'yes')
    end
  end
end
