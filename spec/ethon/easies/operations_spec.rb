require 'spec_helper'

describe Ethon::Easies::Operations do
  let(:easy) { Ethon::Easy.new }

  describe "#handle" do
    it "returns a pointer" do
      expect(easy.handle).to be_a(FFI::Pointer)
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
    let(:headers) { nil }

    before do
      easy.url = url
      easy.timeout = timeout
      easy.connecttimeout = connect_timeout
      easy.followlocation = follow_location
      easy.maxredirs = max_redirs
      easy.userpwd = user_pwd
      easy.httpauth = http_auth
      easy.headers = headers

      easy.prepare
      easy.perform
    end

    it "calls Curl.easy_perform" do
      Ethon::Curl.should_receive(:easy_perform)
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

      it "sets response header" do
        expect(easy.response_header).to be
      end

      context "when request timed out" do
        let(:url) { "http://localhost:3001/?delay=1" }
        let(:timeout) { 1 }

        it "returns operation_timedout" do
          expect(easy.return_code).to eq(:operation_timedout)
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
        end
      end

      context "when follow location" do
        let(:url) { "http://localhost:3001/redirect" }
        let(:follow_location) { true }

        it "follows" do
          expect(easy.response_code).to eq(200)
        end

        context "when infinite redirect loop" do
          let(:url) { "http://localhost:3001/bad_redirect" }
          let(:max_redirs) { 5 }

          context "when max redirect set" do
            it "follows only x times" do
              expect(easy.response_code).to eq(302)
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
      end

      context "when ntlm" do
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

    context "when no url" do
      it "returns url_malformat" do
        expect(easy.perform).to eq(:url_malformat)
      end
    end
  end
end
