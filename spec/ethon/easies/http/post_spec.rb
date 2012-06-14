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
        easy.url.should eq(url)
      end

      it "sets postfield_size" do
        easy.postfieldsize.should eq(0)
      end

      it "sets copy_postfields" do
        easy.copypostfields.should eq("")
      end

      it "makes a post request" do
        easy.prepare
        easy.perform
        easy.response_body.should include('"REQUEST_METHOD":"POST"')
      end
    end

    context "when params" do
      let(:params) { {:a => "1&"} }

      it "attaches escaped to url" do
        easy.url.should eq("#{url}?a=1%26")
      end

      it "sets postfield_size" do
        easy.postfieldsize.should eq(0)
      end

      it "sets copy_postfields" do
        easy.copypostfields.should eq("")
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
        end

        it "is a post" do
          easy.response_body.should include('"REQUEST_METHOD":"POST"')
        end

        it "uses application/x-www-form-urlencoded content type" do
          easy.response_body.should include('"CONTENT_TYPE":"application/x-www-form-urlencoded"')
        end

        it "requests parameterized url" do
          easy.response_body.should include('"REQUEST_URI":"http://localhost:3001/?a=1%26"')
        end
      end
    end

    context "when body" do
      context "when multipart" do
        let(:form) { {:a => File.open(__FILE__, 'r')} }

        it "sets httppost" do
          easy.httppost.should be
        end

        context "when requesting" do
          before do
            easy.prepare
            easy.perform
          end

          it "returns ok" do
            easy.return_code.should eq(:ok)
          end

          it "is a post" do
            easy.response_body.should include('"REQUEST_METHOD":"POST"')
          end

          it "uses multipart/form-data content type" do
            easy.response_body.should include('"CONTENT_TYPE":"multipart/form-data')
          end

          it "submits a body" do
            easy.response_body.should match('"body":".+"')
          end

          it "submits the data" do
            easy.response_body.should include('"rack.request.form_hash":{"a":{"filename":"post_spec.rb"')
          end
        end
      end

      context "when not multipart" do
        let(:form) { {:a => "1&b=2"} }

        it "sets escaped copypostfields" do
          easy.copypostfields.should eq("a=1%26b%3D2")
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
            easy.return_code.should eq(:ok)
          end

          it "is a post" do
            easy.response_body.should include('"REQUEST_METHOD":"POST"')
          end

          it "uses multipart/form-data content type" do
            easy.response_body.should include('"CONTENT_TYPE":"application/x-www-form-urlencoded')
          end

          it "submits a body" do
            easy.response_body.should match('"body":"a=1%26b%3D2"')
          end

          it "submits the data" do
            easy.response_body.should include('"rack.request.form_hash":{"a":"1&b=2"}')
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
          easy.response_body.should include('"REQUEST_URI":"http://localhost:3001/?b=2"')
        end

        it "body contains form" do
          easy.response_body.should include('"body":"a=1"')
        end
      end
    end
  end
end
