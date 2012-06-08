require 'spec_helper'

describe Ethon::Easies::Http::Actions::Post do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:post) { described_class.new(url, {:params => params, :body => form}) }

  describe "#setup" do
    before { post.setup(easy) }

    it "sets url" do
      easy.url.should eq(url)
    end

    it "sets postfield_size" do
      easy.postfield_size.should eq(0)
    end

    it "sets copy_postfields" do
      easy.copy_postfields.should eq("")
    end

    it "makes a post request" do
      easy.prepare
      easy.perform
      easy.response_body.should include('"REQUEST_METHOD":"POST"')
    end

    context "when params" do
      let(:params) { {:a => "1&"} }

      it "attaches escaped to url" do
        easy.url.should eq("#{url}?a=1%26")
      end

      it "sets postfield_size" do
        easy.postfield_size.should eq(0)
      end

      it "sets copy_postfields" do
        easy.copy_postfields.should eq("")
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
      let(:form) { {:a => "1&"} }

      it "sets http_post" do
        easy.http_post.should be
      end

      context "when requesting" do
        before do
          easy.prepare
          easy.perform
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
          easy.response_body.should include('"rack.request.form_hash":{"a":"1&"}')
        end
      end
    end

    context "when params and body" do
      it "sets both"
    end
  end
end
