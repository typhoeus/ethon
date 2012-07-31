require 'spec_helper'

describe Ethon::Easies::Http::Post do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:post) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { post.setup(easy) }

    context "when nothing" do
      it "sets url" do
        expect(easy.url).to eq(url)
      end

      it "sets postfield_size" do
        expect(easy.postfieldsize).to eq(0)
      end

      it "sets copy_postfields" do
        expect(easy.copypostfields).to eq("")
      end

      it "makes a post request" do
        easy.prepare
        easy.perform
        expect(easy.response_body).to include('"REQUEST_METHOD":"POST"')
      end
    end

    context "when params" do
      let(:params) { {:a => "1&"} }

      it "attaches escaped to url" do
        expect(easy.url).to eq("#{url}?a=1%26")
      end

      it "sets postfield_size" do
        expect(easy.postfieldsize).to eq(0)
      end

      it "sets copy_postfields" do
        expect(easy.copypostfields).to eq("")
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "is a post" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"POST"')
        end

        it "uses application/x-www-form-urlencoded content type" do
          expect(easy.response_body).to include('"CONTENT_TYPE":"application/x-www-form-urlencoded"')
        end

        it "requests parameterized url" do
          expect(easy.response_body).to include('"REQUEST_URI":"http://localhost:3001/?a=1%26"')
        end
      end
    end

    context "when body" do
      context "when multipart" do
        let(:form) { {:a => File.open(__FILE__, 'r')} }

        it "sets httppost" do
          expect(easy.httppost).to be
        end

        context "when requesting" do
          before do
            easy.prepare
            easy.perform
          end

          it "returns ok" do
            expect(easy.return_code).to eq(:ok)
          end

          it "is a post" do
            expect(easy.response_body).to include('"REQUEST_METHOD":"POST"')
          end

          it "uses multipart/form-data content type" do
            expect(easy.response_body).to include('"CONTENT_TYPE":"multipart/form-data')
          end

          it "submits a body" do
            expect(easy.response_body).to match('"body":".+"')
          end

          it "submits the data" do
            expect(easy.response_body).to include('"filename":"post_spec.rb"')
          end
        end
      end

      context "when not multipart" do
        let(:form) { {:a => "1&b=2"} }

        it "sets escaped copypostfields" do
          expect(easy.copypostfields).to eq("a=1%26b%3D2")
        end

        it "sets postfieldsize" do
          easy.postfieldsize.should_not be_zero
        end

        context "when requesting" do
          before do
            easy.prepare
            easy.perform
          end

          it "returns ok" do
            expect(easy.return_code).to eq(:ok)
          end

          it "is a post" do
            expect(easy.response_body).to include('"REQUEST_METHOD":"POST"')
          end

          it "uses multipart/form-data content type" do
            expect(easy.response_body).to include('"CONTENT_TYPE":"application/x-www-form-urlencoded')
          end

          it "submits a body" do
            expect(easy.response_body).to match('"body":"a=1%26b%3D2"')
          end

          it "submits the data" do
            expect(easy.response_body).to include('"rack.request.form_hash":{"a":"1&b=2"}')
          end
        end
      end

      context "when string" do
        let(:form) { "{a: 1}" }

        context "when requesting" do
          before do
            easy.prepare
            easy.perform
          end

          it "returns ok" do
            expect(easy.return_code).to eq(:ok)
          end

          it "sends string" do
            expect(easy.response_body).to include('"body":"{a: 1}"')
          end
        end
      end
    end

    context "when params and body" do
      let(:form) { {:a => "1"} }
      let(:params) { {:b => "2"} }

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "url contains params" do
          expect(easy.response_body).to include('"REQUEST_URI":"http://localhost:3001/?b=2"')
        end

        it "body contains form" do
          expect(easy.response_body).to include('"body":"a=1"')
        end
      end
    end
  end
end
