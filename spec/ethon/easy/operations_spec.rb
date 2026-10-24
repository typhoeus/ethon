# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Operations do
  let(:easy) { Ethon::Easy.new }

  describe "#handle" do
    it "returns a pointer" do
      expect(easy.handle).to be_a(FFI::Pointer)
    end

    it "raises when easy_init returns a null pointer" do
      easy.instance_variable_set(:@handle, nil)
      expect(Ethon::Curl).to receive(:easy_init).and_return(FFI::Pointer::NULL)

      expect { easy.handle }.to raise_error(NoMemoryError, "curl_easy_init failed")
    end

    it "rejects a handle inherited across a fork" do
      easy.handle
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          easy.perform
        rescue Exception => e
          writer.write(Marshal.dump([e.class.name, e.message]))
        ensure
          writer.close
        end
      end
      writer.close
      error_class, message = Marshal.load(reader.read)
      Process.wait(pid)
      pid = nil

      expect(error_class).to eq("Ethon::Errors::ForkSafety")
      expect(message).to include("initialized before a fork")
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "rejects cleanup of a handle inherited across a fork" do
      easy.handle
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          easy.cleanup
        rescue Exception => e
          writer.write(e.class.name)
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("Ethon::Errors::ForkSafety")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "rejects creating a new handle after a fork when libcurl was initialized" do
      easy.handle
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Easy.new
          writer.write("ok")
        rescue Exception => e
          writer.write(e.class.name)
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("Ethon::Errors::ForkSafety")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end
  end


  describe "#prepare" do
    it "warns and does nothing" do
      expect(Ethon.logger).to receive(:warn).with(/no longer necessary/)

      easy.prepare
    end
  end

  describe "#cleanup" do
    it "refuses to clean up while attached to a Multi" do
      multi = Ethon::Multi.new
      multi.add(easy)

      expect { easy.cleanup }.to raise_error(Ethon::Errors::EthonError, /attached/)

      multi.delete(easy)
      expect { easy.cleanup }.not_to raise_error
    end

    it "frees the native handle when closing the response body fails" do
      handle = easy.handle
      allow(easy).to receive(:clear_response_body_io).and_raise(IOError, "close failed")

      expect(handle).to receive(:free).and_call_original
      expect { easy.cleanup }.to raise_error(IOError, "close failed")

      expect(easy.instance_variable_get(:@handle)).to be_nil
      expect { easy.cleanup }.to raise_error(Ethon::Errors::EthonError, /cleaned up/)
    end

    it "releases native-backed state" do
      easy.url = "http://localhost:3001/"
      easy.postfields = "body"
      easy.set_read_callback("body")
      easy.headers = { "X-Test" => "yes" }
      easy.errorbuffer = true
      easy.response_body = "response"

      easy.cleanup

      expect(easy.instance_variable_get(:@postfields)).to be_nil
      expect(easy.instance_variable_get(:@header_list)).to be_nil
      expect(easy.instance_variable_get(:@read_callback)).to be_nil
      expect(easy.instance_variable_get(:@request_body)).to be_nil
      expect(easy.instance_variable_get(:@procs)).to be_nil
      expect(easy.instance_variable_get(:@error_buffer)).to be_nil
      expect(easy.response_body).to eq("response")
    end
  end

  describe "multi ownership" do
    it "refuses to perform while attached to a Multi" do
      multi = Ethon::Multi.new
      easy.url = "http://localhost:3001/"
      multi.add(easy)

      expect { easy.perform }.
        to raise_error(Ethon::Errors::EthonError, /attached to a Multi/)
    ensure
      multi.delete(easy) if multi && multi.easy_handles.include?(easy)
    end

    it "performs once the Multi releases the handle" do
      multi = Ethon::Multi.new
      easy.url = "http://localhost:3001/"
      multi.add(easy)
      multi.delete(easy)

      expect(easy.perform).to eq(:ok)
    end
  end

  describe "cleaned up handles" do
    it "does not reset a previous response when performing" do
      easy.response_body = "previous body"
      easy.response_headers = "previous headers"
      easy.cleanup

      expect { easy.perform }.
        to raise_error(Ethon::Errors::EthonError, /cleaned up/)
      expect(easy.response_body).to eq("previous body")
      expect(easy.response_headers).to eq("previous headers")
    end

    it "does not reset a previous response when resetting" do
      easy.url = "http://localhost:3001/"
      easy.response_body = "previous body"
      easy.response_headers = "previous headers"
      easy.cleanup

      expect { easy.reset }.
        to raise_error(Ethon::Errors::EthonError, /cleaned up/)
      expect(easy.url).to eq("http://localhost:3001/")
      expect(easy.response_body).to eq("previous body")
      expect(easy.response_headers).to eq("previous headers")
    end
  end

  describe "reentrancy" do
    it "refuses to clean up while performing" do
      easy.instance_variable_set(:@performing, true)

      expect { easy.cleanup }.
        to raise_error(Ethon::Errors::EthonError, /performing/)
    end

    it "refuses to perform while already performing" do
      easy.instance_variable_set(:@performing, true)

      expect { easy.perform }.
        to raise_error(Ethon::Errors::EthonError, /performing/)
    end

    it "refuses to clean up from a body callback" do
      easy.url = "http://localhost:3001/"
      easy.on_body { easy.cleanup }

      expect { easy.perform }.
        to raise_error(Ethon::Errors::EthonError, /performing/)
      expect(easy.return_code).to eq(:write_error)
    ensure
      easy.cleanup
    end

    it "refuses to clean up from an on_complete callback" do
      easy.url = "http://localhost:3001/"
      easy.on_complete { easy.cleanup }

      expect { easy.perform }.
        to raise_error(Ethon::Errors::EthonError, /completing/)
    ensure
      easy.cleanup
    end
  end

  describe "#perform" do
    let(:url) { nil }
    let(:timeout) { nil }
    let(:timeout_ms) { nil }
    let(:connect_timeout) { nil }
    let(:follow_location) { nil }
    let(:max_redirs) { nil }
    let(:user_pwd) { nil }
    let(:http_auth) { nil }
    let(:headers) { nil }
    let(:protocols) { nil }
    let(:redir_protocols) { nil }
    let(:username) { nil }
    let(:password) { nil }

    before do
      easy.url = url
      easy.timeout = timeout
      easy.timeout_ms = timeout_ms
      easy.connecttimeout = connect_timeout
      easy.followlocation = follow_location
      easy.maxredirs = max_redirs
      easy.httpauth = http_auth
      easy.headers = headers
      easy.protocols = protocols
      easy.redir_protocols = redir_protocols

      if user_pwd
        easy.userpwd = user_pwd
      else
        easy.username = username
        easy.password = password
      end

      easy.perform
    end

    it "calls Curl.easy_perform" do
      expect(Ethon::Curl).to receive(:easy_perform)
      easy.perform
    end

    it "calls Curl.easy_cleanup" do
      expect_any_instance_of(FFI::AutoPointer).to receive(:free)
      easy.cleanup
    end

    it "forgets the handle after cleanup" do
      easy.cleanup

      expect(easy.instance_variable_get(:@handle)).to be_nil
    end

    it "logs" do
      level = Ethon.logger.level
      Ethon.logger.level = Logger::DEBUG
      expect(Ethon.logger).to receive(:debug)
      easy.perform
    ensure
      Ethon.logger.level = level
    end

    it "doesn't log after completing because completing could reset" do
      easy.on_complete{ expect(Ethon.logger).to receive(:debug).never }
      easy.perform
    end

    context "when url" do
      let(:url) { "http://localhost:3001/" }

      it "returns ok" do
        expect(easy.return_code).to eq(:ok)
      end

      it "sets response body" do
        expect(easy.response_body).to be
      end

      it "sets response headers" do
        expect(easy.response_headers).to be
      end

      if Ethon::Easy.supports_timeout_ms?
        context "when request timed out" do
          let(:url) { "http://127.0.0.1:3001/?delay=0.3" }
          let(:timeout_ms) { 100 }

          it "returns operation_timedout" do
            expect(easy.return_code).to eq(:operation_timedout)
          end
        end
      else
        context "when request timed out" do
          let(:url) { "http://127.0.0.1:3001/?delay=1" }
          let(:timeout) { 1 }

          it "returns operation_timedout" do
            expect(easy.return_code).to eq(:operation_timedout)
          end
        end
      end

      context "when connection timed out" do
        let(:url) { "http://localhost:3009" }
        let(:connect_timeout) { 1 }

        it "returns couldnt_connect" do
          expect(easy.return_code).to eq(:couldnt_connect)
        end
      end

      context "when no follow location" do
        let(:url) { "http://localhost:3001/redirect" }
        let(:follow_location) { false }

        it "doesn't follow" do
          expect(easy.response_code).to eq(302)
          expect(easy.redirect_url).to eq("http://localhost:3001/")
        end
      end

      context "when follow location" do
        let(:url) { "http://localhost:3001/redirect" }
        let(:follow_location) { true }

        it "follows" do
          expect(easy.response_code).to eq(200)
          expect(easy.redirect_url).to eq(nil)
        end

        context "when infinite redirect loop" do
          let(:url) { "http://localhost:3001/bad_redirect" }
          let(:max_redirs) { 5 }

          context "when max redirect set" do
            it "follows only x times" do
              expect(easy.response_code).to eq(302)
              expect(easy.redirect_url).to eq("http://localhost:3001/bad_redirect")
            end
          end
        end
      end

      context "when user agent" do
        let(:headers) { { 'User-Agent' => 'Ethon' } }

        it "sets" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"Ethon"')
        end
      end
    end

    context "when auth url" do
      before { easy.url = url }

      context "when basic auth" do
        let(:url) { "http://localhost:3001/auth_basic/username/password" }

        context "when no user_pwd" do
          it "returns 401" do
            expect(easy.response_code).to eq(401)
          end
        end

        context "when invalid user_pwd" do
          let(:user_pwd) { "invalid:invalid" }

          it "returns 401" do
            expect(easy.response_code).to eq(401)
          end
        end

        context "when valid user_pwd" do
          let(:user_pwd) { "username:password" }

          it "returns 200" do
            expect(easy.response_code).to eq(200)
          end
        end

        context "when user and password" do
          let(:username) { "username" }
          let(:password) { "password" }

          it "returns 200" do
            expect(easy.response_code).to eq(200)
          end
        end
      end

      context "when ntlm", :if => (Ethon::Curl.version_info[:features] & Ethon::Curl::VERSION_NTLM) != 0 do
        let(:url) { "http://localhost:3001/auth_ntlm" }
        let(:http_auth) { :ntlm }

        context "when no user_pwd" do
          it "returns 401" do
            expect(easy.response_code).to eq(401)
          end
        end

        context "when user_pwd" do
          let(:user_pwd) { "username:password" }

          it "returns 200" do
            expect(easy.response_code).to eq(200)
          end
        end
      end
    end

    context "when protocols" do
      context "when asking for a allowed url" do
        let(:url) { "http://localhost:3001" }
        let(:protocols) { :http }

        it "returns ok" do
          expect(easy.return_code).to be(:ok)
        end
      end

      context "when asking for a not allowed url" do
        let(:url) { "http://localhost:3001" }
        let(:protocols) { :https }

        it "returns unsupported_protocol" do
          expect(easy.return_code).to be(:unsupported_protocol)
        end
      end
    end

    context "when multiple protocols" do
      context "when asking for a allowed url" do
        let(:protocols) { [:http, :https] }

        context "when http" do
          let(:url) { "http://localhost:3001" }

          it "returns ok for http" do
            expect(easy.return_code).to be(:ok)
          end
        end

        context "when https" do
          let(:url) { "https://localhost:3001" }

          it "returns ssl_connect_error for https" do
            expect(easy.return_code).to be(:ssl_connect_error)
          end
        end
      end

      context "when asking for a not allowed url" do
        let(:url) { "ssh://localhost" }
        let(:protocols) { [:https, :http] }

        it "returns unsupported_protocol" do
          expect(easy.return_code).to be(:unsupported_protocol)
        end
      end
    end

    context "when redir_protocols" do
      context "when redirecting to a not allowed url" do
        let(:url) { "http://localhost:3001/redirect" }
        let(:follow_location) { true }
        let(:redir_protocols) { :https }

        it "returns unsupported_protocol" do
          expect(easy.return_code).to be(:unsupported_protocol)
        end
      end
    end

    context "when no url" do
      it "returns url_malformat" do
        expect(easy.perform).to eq(:url_malformat)
      end
    end

    [false, true].each do |verbose|
      it "raises on_body exceptions when verbose is #{verbose}" do
        easy.url = "http://localhost:3001/"
        easy.verbose = verbose
        error = RuntimeError.new("body callback failed")
        easy.on_body { raise error }

        expect { easy.perform }.to raise_error(error)
      end

      it "calls on_complete before raising on_body exceptions when verbose is #{verbose}" do
        easy.url = "http://localhost:3001/"
        easy.verbose = verbose
        completed = false
        error = RuntimeError.new("body callback failed")
        easy.on_body { raise error }
        easy.on_complete { completed = true }

        expect { easy.perform }.to raise_error(error)
        expect(completed).to be(true)
      end
    end

    it "raises debug callback exceptions" do
      easy.url = "http://localhost:3001/"
      easy.verbose = true
      error = RuntimeError.new("debug callback failed")
      easy.debugfunction { raise error }

      expect { easy.perform }.to raise_error(error)
    end

    it "calls on_complete before raising on_progress exceptions" do
      easy.url = "http://localhost:3001/"
      completed = false
      error = RuntimeError.new("progress callback failed")
      easy.on_progress { raise error }
      easy.on_complete { completed = true }

      expect { easy.perform }.to raise_error(error)
      expect(completed).to be(true)
    end

    it "calls on_complete before raising read callback exceptions" do
      easy.url = "http://localhost:3001/"
      easy.upload = true
      easy.infilesize = 100
      body = Object.new
      def body.read(*)
        raise IOError, "read failed"
      end
      easy.set_read_callback(body)
      completed = false
      easy.on_complete { completed = true }

      expect { easy.perform }.to raise_error(IOError, "read failed")
      expect(completed).to be(true)
    end
  end
end
