# encoding: UTF-8
require 'spec_helper'

describe Orthos::Easy do
  let(:easy) { Orthos::Easy.new }
  let(:value) { "fubar" }

  describe "accessors" do
    let(:options) { Orthos::Easy::OPTIONS }

    it "has read accessors for all OPTIONS" do
      options.all? { |o| easy.respond_to?(o) }.should be_true
    end

    it "has write accessors for all OPTIONS" do
      options.all? { |o| easy.respond_to?("#{o}=") }.should be_true
    end
  end

  describe ".new" do
    it "inits curl" do
      Orthos::Curl.expects(:init)
      easy
    end

    it "defines finalizer" do
      ObjectSpace.expects(:define_finalizer)
      easy
    end
  end

  describe "#prepare" do
    before do
      Orthos::Curl.expects(:set_option).with(:writefunction, easy.body_write_callback, easy.handle)
      Orthos::Curl.expects(:set_option).with(:headerfunction, easy.header_write_callback, easy.handle)
    end

    it "sets write- and headerfunction" do
      easy.prepare
    end

    it "resets @response_body" do
      easy.prepare
      easy.instance_variable_get(:@response_body).should eq("")
    end

    it "resets @response_header" do
      easy.prepare
      easy.instance_variable_get(:@response_header).should eq("")
    end

    context "when option" do
      let(:url) { "http://localhost:3001/" }

      it "sets curl option" do
        easy.url = url
        Orthos::Curl.expects(:set_option).with(:url, url, easy.handle)
        easy.prepare
      end
    end
  end

  describe "#handle" do
    it "returns a pointer" do
      easy.handle.should be_a(FFI::Pointer)
    end
  end

  describe "#perform" do
    let(:url) { nil }
    let(:timeout) { nil }
    let(:connect_timeout) { nil }
    let(:follow_location) { nil }
    let(:max_redirs) { nil }
    let(:user_pwd) { nil }
    let(:http_auth) { nil }

    before do
      easy.url = url
      easy.timeout = timeout
      easy.connect_timeout = connect_timeout
      easy.follow_location = follow_location
      easy.max_redirs = max_redirs
      easy.user_pwd = user_pwd
      easy.http_auth = http_auth
      easy.prepare
      easy.perform
    end

    it "calls Curl.easy_perform" do
      Orthos::Curl.expects(:easy_perform)
      easy.perform
    end

    context "when url" do
      let(:url) { "http://localhost:3001/" }

      it "returns ok" do
        easy.return_code.should eq(:ok)
      end

      it "sets response body" do
        easy.response_body.should be_present
      end

      it "sets response header" do
        easy.response_header.should be_present
      end

      context "when request timed out" do
        let(:url) { "http://localhost:3001/?delay=1" }
        let(:timeout) { 1 }

        it "returns operation_timedout" do
          easy.return_code.should eq(:operation_timedout)
        end
      end

      context "when connection timed out" do
        let(:url) { "http://localhost:3009" }
        let(:connect_timeout) { 1 }

        it "returns couldnt_connect" do
          easy.return_code.should eq(:couldnt_connect)
        end
      end

      context "when no follow location" do
        let(:url) { "http://localhost:3001/redirect" }
        let(:follow_location) { false }

        it "doesn't follow" do
          easy.response_code.should eq(302)
        end
      end

      context "when follow location" do
        let(:url) { "http://localhost:3001/redirect" }
        let(:follow_location) { true }

        it "follows" do
          easy.response_code.should eq(200)
        end

        context "when infinite redirect loop" do
          let(:url) { "http://localhost:3001/bad_redirect" }
          let(:max_redirs) { 5 }

          context "when max redirect set" do
            it "follows only x times" do
              easy.response_code.should eq(302)
            end
          end
        end
      end
    end

    context "when auth url" do
      before { easy.url = url }

      context "when basic auth" do
        let(:url) { "http://localhost:3001/auth_basic/username/password" }

        context "when no user_pwd" do
          it "returns 401" do
            easy.response_code.should eq(401)
          end
        end

        context "when invalid user_pwd" do
          let(:user_pwd) { "invalid:invalid" }

          it "returns 401" do
            easy.response_code.should eq(401)
          end
        end

        context "when valid user_pwd" do
          let(:user_pwd) { "username:password" }

          it "authenticates" do
            easy.response_code.should eq(200)
          end
        end
      end

      context "when ntlm" do
        let(:url) { "http://localhost:3001/auth_ntlm" }
        let(:http_auth) { :ntlm }

        context "when no user_pwd" do
          it "has correct header" do
            easy.response_code.should eq(401)
          end
        end

        context "when user_pwd" do
          let(:user_pwd) { "username:password" }

          it "has correct header" do
            easy.response_code.should eq(200)
          end
        end
      end
    end

    context "when no url" do
      it "returns url_malformat" do
        easy.perform.should eq(:url_malformat)
      end
    end
  end
end
