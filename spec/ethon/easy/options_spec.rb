require 'spec_helper'

describe Ethon::Easy::Options do
  let(:easy) { Ethon::Easy.new }

  [
    :accept_encoding, :dns_cache_timeout, :httppost, :httpget, :nobody, :upload,
    :customrequest, :cainfo, :capath, :connecttimeout, :connecttimeout_ms,
    :forbid_reuse, :followlocation, :httpauth, :infilesize, :interface,
    :keypasswd, :maxredirs, :nosignal, :postfieldsize, :copypostfields, :proxy,
    :proxyauth, :proxyport, :proxytype, :proxyuserpwd, :timeout, :timeout_ms,
    :readdata, :sslcert, :ssl_verifypeer, :ssl_verifyhost, :sslcerttype,
    :sslkey, :sslkeytype, :sslversion, :url, :useragent, :userpwd,
    :verbose, :readfunction
  ].each do |name|
    describe "#{name}=" do
      it "responds_to" do
        expect(easy).to respond_to("#{name}=")
      end

      it "sets option" do
        Ethon::Easy.any_instance.should_receive(:set_callbacks)
        Ethon::Curl.should_receive(:set_option).with do |option, _, _|
          expect(option).to be(name)
        end
        value = case name
        when :httpauth
          :basic
        when :sslversion
          :default
        when :proxytype
          :http
        else
          1
        end
        easy.method("#{name}=").call(value)
      end
    end
  end

  describe "#value_for" do
    context "when option in bool_options" do
      let(:option) { :verbose }

      context "when value true" do
        let(:value) { true }

        it "returns 1" do
          expect(easy.method(:value_for).call(value, :bool)).to eq(1)
        end
      end

      context "when value false" do
        let(:value) { false }

        it "returns 0" do
          expect(easy.method(:value_for).call(value, :bool)).to eq(0)
        end
      end
    end

    context "when value in enum_options" do
      let(:option) { :httpauth }
      let(:value) { :ntlm }

      context "when valid" do
        it "returns value from struct" do
          expect(easy.method(:value_for).call(value, :enum, option)).to eq(8)
        end
      end

      context "when invalid" do
        it "raises Errors::InvalidValue" do
          expect{ easy.method(:value_for).call(:fubar, :enum, :sslversion) }.to raise_error(Ethon::Errors::InvalidValue)
        end
      end
    end

    context "when value in int_options" do
      let(:option) { :maxredirs }
      let(:value) { "2" }

      it "returns value casted to int" do
        expect(easy.method(:value_for).call(value, :int)).to eq(2)
      end
    end

    context "when value in unspecific_options" do
      let(:option) { :url }
      context "when value a string" do
        let(:value) { "www.example.\0com" }

        it "returns zero byte escaped string" do
          expect(easy.method(:value_for).call(value, nil)).to eq("www.example.\\0com")
        end
      end

      context "when value not a string" do
        let(:value) { 1 }

        it "returns value" do
          expect(easy.method(:value_for).call(value, nil)).to eq(1)
        end
      end
    end
  end

  context "when requesting" do
    let(:url) { "localhost:3001" }
    let(:timeout) { nil }
    let(:timeout_ms) { nil }
    let(:connecttimeout) { nil }
    let(:connecttimeout_ms) { nil }

    before do
      easy.url = url
      easy.timeout = timeout
      easy.timeout_ms = timeout_ms
      easy.connecttimeout = connecttimeout
      easy.connecttimeout_ms = connecttimeout_ms
      easy.perform
    end

    context "when timeout" do
      let(:timeout) { 1 }

      context "when request takes longer" do
        let(:url) { "localhost:3001?delay=2" }

        it "times out" do
          expect(easy.return_code).to eq(:operation_timedout)
        end
      end
    end

    context "when connecttimeout" do
      let(:connecttimeout) { 1 }

      context "when cannot connect" do
        let(:url) { "localhost:3002" }

        it "times out" do
          expect(easy.return_code).to eq(:couldnt_connect)
        end
      end
    end

    if Ethon::Curl.version.match("c-ares")
      context "when timeout_ms" do
        let(:timeout_ms) { 900 }

        context "when request takes longer" do
          let(:url) { "localhost:3001?delay=1" }

          it "times out" do
            expect(easy.return_code).to eq(:operation_timedout)
          end
        end
      end

      context "when connecttimeout_ms" do
        let(:connecttimeout_ms) { 1 }

        context "when cannot connect" do
          let(:url) { "localhost:3002" }

          it "times out" do
            expect(easy.return_code).to eq(:couldnt_connect)
          end
        end
      end
    end
  end
end
