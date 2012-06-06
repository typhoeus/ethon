require 'spec_helper'

describe Orthos::Easies::Http do
  let(:easy) { Orthos::Easy.new }

  describe "#http_request" do
    let(:url) { "http://localhost:3001/" }
    let(:action) { :get }
    let(:options) { {} }

    before { easy.http_request(url, action, options) }

    context "when get" do
      it "sets http_get" do
        easy.http_get.should be
      end

      it "sets url" do
        easy.url.should eq(url)
      end

      context "when params" do
        let(:options) { { :params => {:a => "1&"} } }

        it "attaches escaped to url" do
          easy.url.should eq("#{url}?a=1%26")
        end

        context "when requesting" do
          before do
            easy.prepare
            easy.perform
          end

          it "is a get request" do
            easy.response_body.should include('"REQUEST_METHOD":"GET"')
          end

          it "requests parameterized url" do
            easy.response_body.should include('"REQUEST_URI":"http://localhost:3001/?a=1%26"')
          end
        end
      end
    end

    context "when post" do
      let(:action) { :post }

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
        let(:options) { { :params => {:a => "1&"} } }

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
        let(:options) { { :body => {:a => "1&"} } }

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

    context "when put" do
      let(:action) { :put }

      it "sets url" do
        easy.url.should eq(url)
      end

      it "sets upload" do
        easy.upload.should be
      end

      it "sets infile_size" do
        easy.infile_size.should eq(0)
      end

      it "makes a put request" do
        easy.prepare
        easy.perform
        easy.response_body.should include('"REQUEST_METHOD":"PUT"')
      end

      context "when params"
    end

    context "when head" do
      let(:action) { :head }

      it "sets nobody" do
        easy.nobody.should be
      end

      it "sets url" do
        easy.url.should eq(url)
      end

      context "when params" do
        let(:options) { { :params => {:a => "1&"} } }

        it "attaches escaped to url" do
          easy.url.should eq("#{url}?a=1%26")
        end

        context "when requesting" do
          before do
            easy.prepare
            easy.perform
          end

          it "has no body" do
            easy.response_body.should be_empty
          end
        end
      end
    end
  end

  describe "#reset_http_request" do
    before { easy.reset_http_request }

    it "unsets http_get" do
      easy.http_get.should be_nil
    end

    it "unsets http_post" do
      easy.http_post.should be_nil
    end

    it "unsets upload" do
      easy.upload.should be_nil
    end

    it "unsets nobody" do
      easy.nobody.should be_nil
    end

    it "unsets custom_request" do
      easy.custom_request.should be_nil
    end
  end
end
