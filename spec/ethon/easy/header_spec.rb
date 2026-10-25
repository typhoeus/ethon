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

    context "when a later header is invalid" do
      it "does not build a list" do
        expect(Ethon::Curl).not_to receive(:slist_append)

        expect {
          easy.headers = { "X-Ok" => "1", "X-Bad" => "1\r\nInjected: yes" }
        }.to raise_error(Ethon::Errors::InvalidValue, /headers/)
      end
    end

    context "when curl_slist_append fails" do
      it "frees the previous list and raises" do
        pointer = FFI::MemoryPointer.new(:int)
        allow(Ethon::Curl).to receive(:slist_append).and_return(pointer, FFI::Pointer::NULL)
        expect(Ethon::Curl).to receive(:slist_free_all).with(pointer)

        expect { easy.headers = { "A" => "1", "B" => "2" } }.
          to raise_error(NoMemoryError, /curl_slist_append/)
      end
    end

    context "when libcurl rejects the header list" do
      it "frees the new list and keeps the previous headers" do
        easy.headers = { "X-Old" => "yes" }
        old_list = easy.header_list
        pointer = FFI::MemoryPointer.new(:int)
        allow(Ethon::Curl).to receive(:slist_append).and_return(pointer)
        allow(Ethon::Curl).to receive(:set_option).and_call_original
        allow(Ethon::Curl).to receive(:set_option).
          with(:httpheader, pointer, anything).
          and_raise(Ethon::Errors::SetOption.new(:httpheader, :out_of_memory))
        expect(Ethon::Curl).to receive(:slist_free_all).with(pointer)

        expect { easy.headers = { "X-New" => "yes" } }.
          to raise_error(Ethon::Errors::SetOption)

        expect(easy.request_headers).to eq("X-Old" => "yes")
        expect(easy.header_list).to be(old_list)
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

    it "returns an independent snapshot" do
      easy.headers = { 'X-Test' => 'yes' }
      snapshot = easy.request_headers

      snapshot['X-Test'] = 'no'

      expect(easy.request_headers).to eq('X-Test' => 'yes')
      expect(snapshot).not_to be(easy.request_headers)
    end

    it "returns a new empty hash by default" do
      first = easy.request_headers
      first['X-Test'] = 'yes'

      expect(easy.request_headers).to eq({})
    end

    it "does not track later mutations of the caller's hash" do
      headers = { 'X-Test' => 'yes' }
      easy.headers = headers

      headers['X-Test'] = 'no'
      headers['X-Other'] = 'yes'

      expect(easy.request_headers).to eq('X-Test' => 'yes')
    end

    it "sends the snapshot taken when the headers were assigned" do
      headers = { 'X-Test' => 'yes' }
      easy.headers = headers
      headers['X-Test'] = 'no'
      easy.url = "http://localhost:3001/"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"HTTP_X_TEST":"yes"')
      expect(easy.response_body).not_to include('"HTTP_X_TEST":"no"')
    end
  end
end
