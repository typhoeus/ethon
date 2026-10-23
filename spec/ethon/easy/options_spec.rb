# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Options do
  let(:easy) { Ethon::Easy.new }

  describe "callback retention" do
    it "retains callbacks assigned through setters" do
      callback = proc { 0 }

      easy.readfunction = callback

      expect(easy.instance_variable_get(:@procs)[:readfunction]).to be(callback)
    end

    it "removes callbacks set to nil" do
      easy.readfunction = proc { 0 }

      easy.readfunction = nil

      expect(easy.instance_variable_get(:@procs)).not_to have_key(:readfunction)
    end

    it "allows clearing a callback before any were set" do
      expect { easy.writefunction = nil }.not_to raise_error
    end

    it "tracks callbacks independently after duplication" do
      callback = proc { 0 }
      replacement = proc { 0 }
      easy.readfunction = callback

      copy = easy.dup
      copy.readfunction = replacement

      expect(easy.instance_variable_get(:@procs)[:readfunction]).to be(callback)
      expect(copy.instance_variable_get(:@procs)[:readfunction]).to be(replacement)
    end
  end

  describe "#debugfunction" do
    it "stores the callback without replacing Ethon's native callback" do
      callback = proc {}
      easy

      expect(Ethon::Curl).not_to receive(:set_option)
      easy.debugfunction(&callback)

      expect(easy.instance_variable_get(:@user_debug_callback)).to be(callback)
    end

    it "clears the callback when no block is given" do
      easy.debugfunction {}

      easy.debugfunction

      expect(easy.instance_variable_get(:@user_debug_callback)).to be_nil
    end

    it "tracks callbacks independently after duplication" do
      original = proc {}
      replacement = proc {}
      easy.debugfunction(&original)

      copy = easy.dup
      copy.debugfunction(&replacement)

      expect(easy.instance_variable_get(:@user_debug_callback)).to be(original)
      expect(copy.instance_variable_get(:@user_debug_callback)).to be(replacement)
    end
  end

  describe "callback signatures" do
    let(:unsupported_callbacks) do
      [
        :ioctlfunction, :seekfunction, :sockoptfunction, :opensocketfunction,
        :closesocketfunction, :ssl_ctx_function, :conv_to_network_function,
        :conv_from_network_function, :conv_from_utf8_function,
        :chunk_bgn_function, :chunk_end_function, :fnmatch_function,
        :ssh_keyfunction
      ]
    end

    it "keeps callbacks with the read/write ABI supported" do
      supported_callbacks = [:writefunction, :readfunction, :headerfunction, :interleavefunction]

      supported_callbacks.each do |option|
        expect(Ethon::Curl.easy_options(nil)[option][:type]).to eq(:callback)
      end
    end

    it "does not register callbacks with unsupported ABIs" do
      easy
      expect(Ethon::Curl).not_to receive(:easy_setopt)

      unsupported_callbacks.each do |option|
        expect {
          easy.public_send("#{option}=", proc {})
        }.to raise_error(NotImplementedError, /#{option} callback type not implemented/)
      end
    end
  end

  describe "named option values" do
    it "accepts enum strings and symbols equally" do
      expect(Ethon::Curl).to receive(:easy_setopt).with(easy.handle, anything, :long, 1).twice.and_return(:ok)

      Ethon::Curl.set_option(:netrc, :optional, easy.handle)
      Ethon::Curl.set_option(:netrc, "optional", easy.handle)
    end

    it "accepts bitmask strings and symbols equally" do
      expect(Ethon::Curl).to receive(:easy_setopt).with(easy.handle, anything, :long, 2).twice.and_return(:ok)

      Ethon::Curl.set_option(:httpauth, :digest, easy.handle)
      Ethon::Curl.set_option(:httpauth, "digest", easy.handle)
    end

    it "combines mixed string and symbol bitmask arrays" do
      expect(Ethon::Curl).to receive(:easy_setopt).with(easy.handle, anything, :long, 3).and_return(:ok)

      Ethon::Curl.set_option(:httpauth, ["basic", :digest], easy.handle)
    end

    it "resolves named bitmask aliases" do
      expect(Ethon::Curl).to receive(:easy_setopt).with(easy.handle, anything, :long, 7).and_return(:ok)

      Ethon::Curl.set_option(:postredir, "post_all", easy.handle)
    end

    it "preserves integer enum and bitmask values" do
      expect(Ethon::Curl).to receive(:easy_setopt).with(easy.handle, anything, :long, 123).twice.and_return(:ok)

      Ethon::Curl.set_option(:netrc, 123, easy.handle)
      Ethon::Curl.set_option(:httpauth, 123, easy.handle)
    end

    it "rejects unknown enum values" do
      easy
      expect(Ethon::Curl).not_to receive(:easy_setopt)

      expect { Ethon::Curl.set_option(:netrc, "unknown", easy.handle) }.
        to raise_error(Ethon::Errors::InvalidValue, /unknown.*netrc/)
    end

    it "rejects unknown bitmask values" do
      easy
      expect(Ethon::Curl).not_to receive(:easy_setopt)

      expect { Ethon::Curl.set_option(:httpauth, :unknown, easy.handle) }.
        to raise_error(Ethon::Errors::InvalidValue, /unknown.*httpauth/)
    end

    it "rejects unknown values in bitmask arrays" do
      easy
      expect(Ethon::Curl).not_to receive(:easy_setopt)

      expect { Ethon::Curl.set_option(:httpauth, [:basic, "unknown"], easy.handle) }.
        to raise_error(Ethon::Errors::InvalidValue, /unknown.*httpauth/)
    end

    it "rejects non-numeric integer values" do
      easy

      expect { Ethon::Curl.set_option(:timeout, "abc", easy.handle) }.
        to raise_error(Ethon::Errors::InvalidValue, /timeout/)
    end

    it "rejects non-finite integer values" do
      easy

      expect { Ethon::Curl.set_option(:timeout, Float::INFINITY, easy.handle) }.
        to raise_error(Ethon::Errors::InvalidValue, /timeout/)
    end
  end

  [
    :accept_encoding, :cainfo, :capath, :connecttimeout, :connecttimeout_ms, :cookie,
    :cookiejar, :cookiefile, :copypostfields, :customrequest, :dns_cache_timeout,
    :followlocation, :forbid_reuse, :http_version, :httpauth, :httpget, :httppost,
    :infilesize, :interface, :keypasswd, :maxredirs, :nobody, :nosignal,
    :postfieldsize, :postredir, :protocols, :proxy, :proxyauth, :proxyport, :proxytype,
    :proxyuserpwd, :readdata, :readfunction, :redir_protocols, :ssl_verifyhost,
    :ssl_verifypeer, :sslcert, :sslcerttype, :sslkey, :sslkeytype, :sslversion,
    :timeout, :timeout_ms, :unrestricted_auth, :upload, :url, :useragent,
    :userpwd, :verbose, :pipewait, :dns_shuffle_addresses, :path_as_is
  ].each do |name|
    describe "#{name}=" do
      it "responds_to" do
        expect(easy).to respond_to("#{name}=")
      end

      it "sets option" do
        expect_any_instance_of(Ethon::Easy).to receive(:set_callbacks)
        expect(Ethon::Curl).to receive(:set_option).with(name, anything, anything)
        value = case name
        when :http_version
          :httpv1_0
        when :httpauth
          :basic
        when :protocols, :redir_protocols
          :http
        when :postredir
          :post_301
        when :proxytype
          :http
        when :sslversion
          :default
        when :httppost
          FFI::Pointer::NULL
        else
          1
        end
        easy.method("#{name}=").call(value)
      end
    end
  end

  describe '#escape?' do
    context 'by default' do
      it 'returns true' do
        expect(easy.escape?).to be_truthy
      end
    end

    context 'when #escape=nil' do
      it 'returns true' do
        easy.escape = nil
        expect(easy.escape?).to be_truthy
      end
    end

    context 'when #escape=true' do
      it 'returns true' do
        easy.escape = true
        expect(easy.escape?).to be_truthy
      end
    end

    context 'when #escape=false' do
      it 'returns true' do
        easy.escape = false
        expect(easy.escape?).to be_falsey
      end
    end
  end

  describe '#multipart?' do
    context 'by default' do
      it 'returns false' do
        expect(easy.multipart?).to be_falsey
      end
    end

    context 'when #multipart=nil' do
      it 'returns false' do
        easy.multipart = nil
        expect(easy.multipart?).to be_falsey
      end
    end

    context 'when #multipart=true' do
      it 'returns true' do
        easy.multipart = true
        expect(easy.multipart?).to be_truthy
      end
    end

    context 'when #multipart=false' do
      it 'returns false' do
        easy.multipart = false
        expect(easy.multipart?).to be_falsey
      end
    end
  end

  describe "#multipart_form=" do
    it "retains the form after installing its pointer" do
      form = double(:form, :first => double(:first, :read_pointer => FFI::Pointer::NULL))

      expect(easy).to receive(:httppost=) do
        expect(easy.instance_variable_get(:@multipart_form)).to be_nil
      end

      easy.multipart_form = form

      expect(easy.instance_variable_get(:@multipart_form)).to be(form)
    end

    it "clears the native pointer before releasing the form" do
      form = double(:form)
      easy.instance_variable_set(:@multipart_form, form)

      expect(easy).to receive(:httppost=).with(nil) do
        expect(easy.instance_variable_get(:@multipart_form)).to be(form)
      end

      easy.multipart_form = nil

      expect(easy.instance_variable_get(:@multipart_form)).to be_nil
    end
  end

  describe "#httppost=" do
    it "raises unless given a FFI::Pointer" do
      expect{ easy.httppost = 1 }.to raise_error(Ethon::Errors::InvalidValue)
    end
  end

  describe "#errorbuffer=" do
    it "raises when setting a buffer smaller than CURL_ERROR_SIZE" do
      expect{ Ethon::Curl.set_option(:errorbuffer, FFI::MemoryPointer.new(:char, 10), easy.handle) }.to raise_error(Ethon::Errors::InvalidValue)
    end

    it "accepts a large enough buffer" do
      expect(Ethon::Curl.set_option(:errorbuffer, FFI::MemoryPointer.new(:char, 256), easy.handle)).to eq(:ok)
      expect(Ethon::Curl.set_option(:errorbuffer, nil, easy.handle)).to eq(:ok)
    end

    it "retains the buffer on the native handle" do
      easy.errorbuffer = true

      expect(easy.handle.error_buffer).to be(easy.instance_variable_get(:@error_buffer))
    end

    it "releases the buffer after clearing the native option" do
      easy.errorbuffer = true
      buffer = easy.instance_variable_get(:@error_buffer)

      expect(Ethon::Curl).to receive(:set_option).with(:errorbuffer, nil, easy.handle) do
        expect(easy.handle.error_buffer).to be(buffer)
      end

      easy.errorbuffer = false

      expect(easy.handle.error_buffer).to be_nil
    end
  end

  describe "#error_message" do
    let(:url) { "http://localhost:3001/bad_redirect" }

    before do
      easy.url = url
      easy.followlocation = true
      easy.maxredirs = 1
    end

    context "when errorbuffer is not enabled" do
      it "returns nil" do
        easy.perform
        expect(easy.return_code).to eq(:too_many_redirects)
        expect(easy.error_message).to be_nil
      end
    end

    context "when errorbuffer is enabled" do
      before { easy.errorbuffer = true }

      it "returns the detailed error" do
        easy.perform
        expect(easy.return_code).to eq(:too_many_redirects)
        expect(easy.error_message).to include("1").and match(/redirect/i)
        expect(easy.mirror.options[:error_message]).to eq(easy.error_message)
      end

      it "returns nil when the request succeeds" do
        easy.url = "http://localhost:3001/"
        easy.perform
        expect(easy.return_code).to eq(:ok)
        expect(easy.error_message).to be_nil
      end

      it "is cleared between requests" do
        easy.perform
        expect(easy.error_message).not_to be_nil
        easy.url = "http://localhost:3001/"
        easy.perform
        expect(easy.error_message).to be_nil
      end

      it "returns nil once disabled" do
        easy.perform
        easy.errorbuffer = false
        expect(easy.error_message).to be_nil
      end

      it "works with multi" do
        easy.url = "http://localhost:3009/"
        multi = Ethon::Multi.new
        multi.add(easy)
        multi.perform
        expect(easy.return_code).to eq(:couldnt_connect)
        expect(easy.error_message).to include("3009").and match(/connect/i)
      end
    end
  end

  context "when requesting" do
    let(:url) { "localhost:3001" }
    let(:timeout) { nil }
    let(:timeout_ms) { nil }
    let(:connecttimeout) { nil }
    let(:connecttimeout_ms) { nil }
    let(:userpwd) { nil }

    before do
      easy.url = url
      easy.timeout = timeout
      easy.timeout_ms = timeout_ms
      easy.connecttimeout = connecttimeout
      easy.connecttimeout_ms = connecttimeout_ms
      easy.userpwd = userpwd
      easy.perform
    end

    context "when userpwd" do
      context "when contains /" do
        let(:url) { "localhost:3001/auth_basic/test/te%2Fst" }
        let(:userpwd) { "test:te/st" }

        it "works" do
          expect(easy.response_code).to eq(200)
        end
      end
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

    if Ethon::Easy.supports_timeout_ms?
      context "when timeout_ms" do
        let(:timeout_ms) { 100 }

        context "when request takes longer" do
          let(:url) { "localhost:3001?delay=1" }

          it "times out" do
            expect(easy.return_code).to eq(:operation_timedout)
          end
        end
      end

      context "when connecttimeout_ms" do
        let(:connecttimeout_ms) { 100 }

        context "when cannot connect" do
          let(:url) { "localhost:3002" }

          it "times out" do
            # this can either lead to a timeout or couldnt connect depending on which happens first
            expect([:couldnt_connect, :operation_timedout]).to include(easy.return_code)
          end
        end
      end
    end
  end

  describe "libcurl option table" do
    let(:options) { Ethon::Curl.easy_options(nil) }

    it "maps tcp_fastopen to CURLOPT_TCP_FASTOPEN (244), not accepttimeout_ms" do
      expect(options[:tcp_fastopen][:opt]).to eq(244)
      expect(options[:accepttimeout_ms][:opt]).to eq(212)
    end

    it "declares TLS auth types as string options" do
      expect(options[:tlsauth_type][:type]).to eq(:string)
      expect(options[:proxy_tlsauth_type][:type]).to eq(:string)
    end

    it "uses the curl_off_t callback ABI for xferinfo" do
      expect(options[:xferinfofunction][:type]).to eq(:xferinfo_callback)
      expect(options[:progressfunction][:type]).to eq(:progress_callback)
    end
  end

  describe "#tlsauth_type=" do
    before { easy }

    it "normalizes :srp to the string libcurl expects" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :string, "SRP").and_return(:ok)

      expect(easy.tlsauth_type = :srp).to eq(:srp)
    end

    it "normalizes lowercase strings" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :string, "SRP").and_return(:ok)

      easy.tlsauth_type = "srp"
    end

    it "clears the option for :none" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :string, nil).and_return(:ok)

      easy.tlsauth_type = :none
    end

    it "passes through other values" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :string, "custom").and_return(:ok)

      easy.tlsauth_type = "custom"
    end

    it "normalizes the proxy type as well" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :string, "SRP").and_return(:ok)

      easy.proxy_tlsauth_type = :srp
    end
  end

  describe "option coercion branches" do
    before { easy }

    it "sets :none options to one" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :long, 1).and_return(:ok)

      Ethon::Curl.set_option(:sslengine_default, false, easy.handle)
    end

    it "sets :time options as longs" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :long, 42).and_return(:ok)

      Ethon::Curl.set_option(:timevalue, "42", easy.handle)
    end

    it "sets :off_t options as int64" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :int64, 2**40).and_return(:ok)

      Ethon::Curl.set_option(:maxfilesize_large, 2**40, easy.handle)
    end

    it "rejects unsupported object options" do
      expect { easy.stderr = 1 }.to raise_error(NotImplementedError, /stderr/)
    end

    it "rejects unsupported callback data options" do
      expect { easy.writeheader = 1 }.to raise_error(NotImplementedError, /writeheader/)
    end

    it "rejects an unknown option namespace" do
      expect { Ethon::Curl.set_option(:url, "http://example.com", easy.handle, :bogus) }.
        to raise_error(NameError, /unknown type bogus/)
    end

    it "rejects enum options without valid metadata" do
      expect {
        Ethon::Curls::Options.option(:easy, :bogus_enum, :enum, 999, nil)
      }.to raise_error(TypeError, /Expected opts/)
    end

    it "rejects bitmask options without valid metadata" do
      expect {
        Ethon::Curls::Options.option(:easy, :bogus_bitmask, :bitmask, 999, nil)
      }.to raise_error(TypeError, /Expected opts/)
    end

    it "detects cyclic named option aliases" do
      values = { :a => :b, :b => :a }

      expect { Ethon::Curl.named_option_value(:bogus, :a, values) }.
        to raise_error(Ethon::Errors::InvalidValue)
    end

    it "resolves named arrays of aliases" do
      values = { :all => [:a, :b], :a => 1, :b => 2 }

      expect(Ethon::Curl.named_option_value(:bogus, :all, values)).to eq(3)
    end

    it "accepts progress callbacks" do
      callback = proc { 0 }

      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :progress_callback, callback).and_return(:ok)

      Ethon::Curl.set_option(:progressfunction, callback, easy.handle)
    end

    it "rejects non-proc progress callbacks" do
      expect {
        Ethon::Curl.set_option(:progressfunction, 1, easy.handle)
      }.to raise_error(Ethon::Errors::InvalidValue)
    end

    it "rejects non-proc xferinfo callbacks" do
      expect {
        Ethon::Curl.set_option(:xferinfofunction, 1, easy.handle)
      }.to raise_error(Ethon::Errors::InvalidValue)
    end
  end
end
