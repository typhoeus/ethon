# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Http::Put do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:options) { Hash.new }
  let(:put) { described_class.new(url, options.merge({:params => params, :body => form})) }

  describe "#setup" do
    context "when nothing" do
      it "sets url" do
        put.setup(easy)
        expect(easy.url).to eq(url)
      end

      it "sets upload" do
        expect(easy).to receive(:upload=).with(true)
        put.setup(easy)
      end

      it "sets infilesize" do
        expect(easy).to receive(:infilesize=).with(0)
        put.setup(easy)
      end

      context "when requesting" do
        it "makes a put request" do
          put.setup(easy)
          easy.perform
          expect(easy.response_body).to include('"REQUEST_METHOD":"PUT"')
        end
      end
    end

    context "when params" do
      let(:params) { {:a => "1&"} }

      it "attaches escaped to url" do
        put.setup(easy)
        expect(easy.url).to eq("#{url}?a=1%26")
      end

      context "with arrays" do
        let(:params) { {:a => %w( foo bar )} }

        context "by default" do
          it "encodes them with indexes" do
            put.setup(easy)
            expect(easy.url).to eq("#{url}?a%5B0%5D=foo&a%5B1%5D=bar")
          end
        end

        context "when params_encoding is :rack" do
          let(:options) { {:params_encoding => :rack} }
          it "encodes them without indexes" do
            put.setup(easy)
            expect(easy.url).to eq("#{url}?a%5B%5D=foo&a%5B%5D=bar")
          end
        end
      end

      it "sets upload" do
        expect(easy).to receive(:upload=).with(true)
        put.setup(easy)
      end

      it "sets infilesize" do
        expect(easy).to receive(:infilesize=).with(0)
        put.setup(easy)
      end

      context "when requesting" do
        before do
          put.setup(easy)
          easy.perform
        end

        it "makes a put request" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"PUT"')
        end
      end
    end

    context "when body" do
      let(:form) { {:a => "1&b=2"} }

      it "sets infilesize" do
        expect(easy).to receive(:infilesize=).with(11)
        put.setup(easy)
      end

      it "sets readfunction" do
        expect(easy).to receive(:readfunction)
        put.setup(easy)
      end

      it "sets upload" do
        expect(easy).to receive(:upload=).with(true)
        put.setup(easy)
      end

      context "when requesting" do
        context "sending string body" do
          before do
            easy.headers = { 'Expect' => '' }
            put.setup(easy)
            easy.perform
          end

          it "makes a put request" do
            expect(easy.response_body).to include('"REQUEST_METHOD":"PUT"')
          end

          it "submits a body" do
            expect(easy.response_body).to include('"body":"a=1%26b%3D2"')
          end
        end

        context "when injecting a file as body" do
          let(:file) { File.open(__FILE__) }
          let(:easy) do
            e = Ethon::Easy.new(:url => url, :upload => true)
            e.set_read_callback(file)
            e.infilesize = File.size(file.path)
            e
          end

          before do
            easy.headers = { 'Expect' => '' }
            easy.perform
          end

          it "submits file" do
            expect(easy.response_body).to include("injecting")
          end
        end
      end

      context "when arrays" do
        let(:form) { {:a => %w( foo bar )} }

        before do
          put.setup(easy)
          easy.perform
        end

        context "by default" do
          it "submits an indexed, escaped representation" do
            expect(easy.response_body).to include('"body":"a%5B0%5D=foo&a%5B1%5D=bar"')
          end
        end

        context "when params_encoding is :rack" do
          let(:options) { {:params_encoding => :rack} }

          it "submits an non-indexed, escaped representation" do
            expect(easy.response_body).to include('"body":"a%5B%5D=foo&a%5B%5D=bar"')
          end
        end
      end
    end

    context "when params and body" do
      # TODO: Add tests for params + body
    end

    context "when multipart body" do
      let(:file) { File.open(__FILE__) }
      let(:form) { {:a => "1", :b => file} }

      it "sets httppost instead of upload" do
        expect(easy).to receive(:httppost=)
        expect(easy).not_to receive(:upload=)
        put.setup(easy)
      end

      it "materializes form" do
        put.setup(easy)
        expect(put.form.first.read_pointer).not_to be_nil
      end

      context "when requesting" do
        before do
          put.setup(easy)
          easy.perform
        end

        it "makes a put request" do
          expect(easy.response_body).to include('"REQUEST_METHOD":"PUT"')
        end

        it "submits multipart form data" do
          expect(easy.response_body).to include("multipart/form-data")
        end
      end
    end
  end
end
