# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'stringio'

describe "duplicating an Easy handle" do
  let(:url) { "http://localhost:3001/" }

  describe "callbacks" do
    it "keeps a custom write callback working on the duplicate" do
      received = String.new
      easy = Ethon::Easy.new
      easy.url = url
      easy.writefunction = proc do |stream, size, num, _|
        received << stream.read_string(size * num)
        size * num
      end

      copy = easy.dup
      copy.perform

      expect(received).to include('"REQUEST_METHOD":"GET"')
      expect(copy.response_body).to be_empty
    end

    it "keeps a custom read callback on the duplicate" do
      body = "abc"
      reads = 0
      easy = Ethon::Easy.new
      easy.url = url
      easy.upload = true
      easy.infilesize = body.bytesize
      easy.readfunction = proc do |stream, _, _, _|
        reads += 1
        if reads == 1
          stream.write_string(body, body.bytesize)
          body.bytesize
        else
          0
        end
      end

      copy = easy.dup

      expect(copy.read_callback).to be_a(Proc)
      expect(copy.perform).to eq(:ok)
      expect(JSON.parse(copy.response_body)["body"]).to eq(body)
    end

    it "replays a consumed read body on the duplicate" do
      body = StringIO.new("hello-io")
      easy = Ethon::Easy.new
      easy.url = url
      easy.upload = true
      easy.infilesize = body.string.bytesize
      easy.set_read_callback(body)

      expect(easy.perform).to eq(:ok)

      copy = easy.dup

      expect(copy.perform).to eq(:ok)
      expect(JSON.parse(copy.response_body)["body"]).to eq("hello-io")
    end

    it "binds the duplicate's progress callback to the duplicate" do
      called = []
      easy = Ethon::Easy.new
      easy.url = url
      easy.on_progress { called << :original }
      copy = easy.dup

      # Clearing the copy's list must not fall back to the original's list.
      copy.on_progress.clear
      copy.perform

      expect(called).to be_empty
    end

    it "keeps on_progress effective when a custom progress function was installed first" do
      custom = 0
      progress = 0
      easy = Ethon::Easy.new
      easy.url = url
      easy.xferinfofunction = proc { |*| custom += 1; 0 }
      easy.on_progress { progress += 1 }

      copy = easy.dup
      copy.perform

      expect(progress).to be > 0
      expect(custom).to eq(0)
    end

    it "keeps on_progress effective over a custom progress function" do
      custom = 0
      progress = 0
      easy = Ethon::Easy.new
      easy.url = url
      easy.progressfunction = proc { |*| custom += 1; 0 }
      easy.on_progress { progress += 1 }

      copy = easy.dup
      copy.perform

      expect(progress).to be > 0
      expect(custom).to eq(0)
    end

    it "keeps a custom progress function installed after on_progress" do
      custom = 0
      progress = 0
      easy = Ethon::Easy.new
      easy.url = url
      easy.on_progress { progress += 1 }
      easy.xferinfofunction = proc { |*| custom += 1; 0 }

      copy = easy.dup
      copy.perform

      expect(custom).to be > 0
      expect(progress).to eq(0)
    end

    it "does not depend on the original handle staying alive" do
      calls = 0
      original = Ethon::Easy.new
      original.url = url
      original.on_progress { calls += 1 }
      copy = original.dup

      original.cleanup
      original = nil
      GC.start

      expect(copy.perform).to eq(:ok)
      expect(calls).to be > 0
    end
  end

  describe "multipart bodies" do
    let(:file) { File.open(__FILE__) }
    after { file.close }

    it "preserves the native multipart body without aliasing the original MIME" do
      easy = Ethon::Easy.new
      easy.http_request("#{url}file", :post, :body => { :file => file })
      easy.headers = { "Expect" => "" }
      original_mime = easy.mime

      copy = easy.dup

      if Ethon::Curl.respond_to?(:mime_init)
        expect(original_mime).to be_a(Ethon::Curl::Mime)
        expect(copy.mime).to be_nil
      end

      original = easy
      original.cleanup
      original = nil
      GC.start

      expect(copy.perform).to eq(:ok)
      response = JSON.parse(copy.response_body)
      expect(response["filename"]).to eq(File.basename(__FILE__))
      expect(response["content"]).not_to be_empty
    end

    it "does not send an inherited multipart body for the next request" do
      easy = Ethon::Easy.new
      easy.http_request("#{url}file", :post, :body => { :file => file })
      copy = easy.dup

      copy.http_request("#{url}next", :get)
      copy.perform

      response = JSON.parse(copy.response_body)
      expect(response["REQUEST_METHOD"]).to eq("GET")
      expect(response["CONTENT_TYPE"]).to be_nil
      expect(response["body"]).to eq("")
    end
  end

  describe "request state" do
    it "keeps custom headers after the original is cleaned up" do
      easy = Ethon::Easy.new
      easy.url = url
      easy.headers = { "X-Original" => "yes" }
      copy = easy.dup

      original = easy
      original.cleanup
      original = nil
      GC.start

      expect(copy.perform).to eq(:ok)
      expect(copy.response_body).to include('"HTTP_X_ORIGINAL":"yes"')
    end
  end

  describe "attached to a Multi" do
    let(:multi) { Ethon::Multi.new }
    let(:easy) { Ethon::Easy.new(:url => url) }

    after { multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up) }

    it "refuses to duplicate an attached Easy" do
      multi.add(easy)

      expect { easy.dup }.
        to raise_error(Ethon::Errors::EthonError, /still attached to a Multi/)
    end

    it "refuses to clone an attached Easy" do
      multi.add(easy)

      expect { easy.clone }.
        to raise_error(Ethon::Errors::EthonError, /still attached to a Multi/)
    end

    it "duplicates an Easy that was removed again" do
      multi.add(easy)
      multi.delete(easy)

      copy = easy.dup

      expect(copy.perform).to eq(:ok)
      expect(copy.response_code).to eq(200)
    end

    it "refuses to duplicate from a transfer callback" do
      multi.add(easy)
      easy.on_body { easy.dup }

      expect { multi.perform }.
        to raise_error(Ethon::Errors::EthonError, /still attached to a Multi/)
      expect(multi.easy_handles).to be_empty
    end
  end

  describe "transfer state" do
    it "starts with no return code or pending callback error" do
      easy = Ethon::Easy.new
      easy.return_code = :ok
      easy.instance_variable_set(:@callback_error, RuntimeError.new("boom"))

      copy = easy.dup

      expect(copy.return_code).to be_nil
      expect { copy.send(:raise_callback_error) }.not_to raise_error
    end
  end
end
