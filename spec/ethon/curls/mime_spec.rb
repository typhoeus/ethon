# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'tempfile'
require 'tmpdir'

describe Ethon::Curl::Mime do
  let(:easy) { Ethon::Easy.new }
  let(:mime) { described_class.new(easy) }

  describe "#addpart" do
    it "returns a part owned by the mime" do
      part = mime.addpart

      expect(part).to be_a(Ethon::Curl::MimePart)
      expect(part.mime).to be(mime)
    end

    it "raises when libcurl cannot allocate a part" do
      allow(Ethon::Curl).to receive(:mime_addpart).and_return(FFI::Pointer::NULL)

      expect { mime.addpart }.to raise_error(NoMemoryError, "curl_mime_addpart failed")
    end
  end

  describe "MimePart" do
    let(:part) { mime.addpart }

    it "sets form fields" do
      expect {
        part.name = "field"
        part.data = "value"
        part.type = "text/plain"
      }.not_to raise_error
    end

    it "sets files" do
      Tempfile.create do |file|
        file.write("contents")
        file.flush

        part.name = "file"
        part.file = file.path

        expect(part.handle).to be_a(FFI::Pointer)
      end
    end

    it "sets an encoder" do
      expect(Ethon::Curl).to receive(:mime_encoder).
        with(part.handle, "base64").and_return(:ok)

      part.encoder = "base64"
    end

    {
      :name => [:mime_name, [nil]],
      :filename => [:mime_filename, [nil]],
      :type => [:mime_type, [nil]],
      :encoder => [:mime_encoder, [nil]],
      :file => [:mime_filedata, [nil]],
      :data => [:mime_data, [nil, 0]]
    }.each do |setter, (function, arguments)|
      it "clears #{setter} with nil" do
        expect(Ethon::Curl).to receive(function).
          with(part.handle, *arguments).and_return(:ok)

        part.public_send("#{setter}=", nil)
      end
    end

    it "clears every part field without a libcurl error" do
      Tempfile.create do |file|
        part.name = "field"
        part.filename = "file.txt"
        part.type = "text/plain"
        part.encoder = "base64"
        part.file = file.path
        part.data = "value"

        expect {
          part.name = nil
          part.filename = nil
          part.type = nil
          part.encoder = nil
          part.file = nil
          part.data = nil
        }.not_to raise_error
      end
    end

    it "accepts a new value after a field was cleared" do
      part.name = "first"
      part.name = nil
      part.name = "second"

      part.data = "first"
      part.data = nil
      part.data = "second"

      expect { easy.mime = mime }.not_to raise_error
    end

    it "raises when a curl_mime_* call fails" do
      allow(Ethon::Curl).to receive(:mime_name).and_return(:out_of_memory)

      expect { part.name = "field" }.to raise_error(Ethon::Errors::Mime, /memory/i)
    end

    it "raises when curl_mime_headers fails" do
      allow(Ethon::Curl).to receive(:mime_headers).and_return(:out_of_memory)

      expect { part.headers = ["X-Test: 1"] }.
        to raise_error(Ethon::Errors::Mime, /memory/i)
    end

    it "rejects header values containing CRLF" do
      expect { part.headers = { "X-Test" => "1\r\nX-Injected: yes" } }.
        to raise_error(Ethon::Errors::InvalidValue, /headers/)
      expect { part.headers = ["X-Test: 1\nX-Injected: yes"] }.
        to raise_error(Ethon::Errors::InvalidValue, /headers/)
    end

    it "rejects header values containing NUL" do
      expect { part.headers = { "X-Test" => "1\0" } }.
        to raise_error(Ethon::Errors::InvalidValue, /headers/)
    end

    it "rejects a content type containing CRLF" do
      expect(Ethon::Curl).not_to receive(:mime_type)

      expect { part.type = "text/plain\r\nX-Injected: yes" }.
        to raise_error(Ethon::Errors::InvalidValue, /type/)
    end

    it "rejects a content type containing a lone CR or LF" do
      ["text/plain\r", "text/plain\n"].each do |value|
        expect { part.type = value }.
          to raise_error(Ethon::Errors::InvalidValue, /type/)
      end
    end

    it "rejects an encoder containing CRLF" do
      expect(Ethon::Curl).not_to receive(:mime_encoder)

      expect { part.encoder = "base64\r\nX-Injected: yes" }.
        to raise_error(Ethon::Errors::InvalidValue, /encoder/)
    end

    it "rejects a part name containing CRLF" do
      expect(Ethon::Curl).not_to receive(:mime_name)

      expect { part.name = "field\r\nX-Injected: yes" }.
        to raise_error(Ethon::Errors::InvalidValue, /name/)
    end

    it "rejects a filename containing CRLF" do
      expect(Ethon::Curl).not_to receive(:mime_filename)

      expect { part.filename = "file\r\nX-Injected: yes" }.
        to raise_error(Ethon::Errors::InvalidValue, /filename/)
    end

    it "rejects lone CR and LF in names and filenames" do
      [["name", :name], ["filename", :filename]].each do |value, setter|
        ["#{value}\r", "#{value}\n"].each do |bad|
          expect { part.public_send("#{setter}=", bad) }.
            to raise_error(Ethon::Errors::InvalidValue, /#{setter}/)
        end
      end
    end

    it "still accepts valid names and filenames" do
      expect {
        part.name = "field"
        part.filename = "report.csv"
      }.not_to raise_error
    end

    it "still sends a valid content type" do
      easy.url = "http://localhost:3001/echo"
      part.name = "field"
      part.type = "text/csv"
      part.data = "a,b"
      easy.mime = mime

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include("Content-Type: text/csv\r\n")
    end

    [:name, :filename, :type, :encoder, :file].each do |setter|
      it "rejects NUL bytes in #{setter}" do
        expect { part.public_send("#{setter}=", "a\0b") }.
          to raise_error(Ethon::Errors::InvalidValue, /#{setter}/)
      end
    end

    it "keeps NUL bytes in part data" do
      expect(Ethon::Curl).to receive(:mime_data).
        with(part.handle, "a\0b", 3).and_return(:ok)

      part.data = "a\0b"
    end

    it "clears headers with an empty string" do
      expect(Ethon::Curl).to receive(:mime_headers).
        with(part.handle, nil, 0).and_return(:ok)

      part.headers = ""
    end

    it "ignores empty header lines in an array" do
      expect(Ethon::Curl::Slist).to receive(:build).with(["X-Test: 1"]).and_return(nil)

      part.headers = ["", "X-Test: 1"]
    end

    it "releases a partially built header list when an append fails" do
      first = FFI::MemoryPointer.new(:pointer)
      allow(Ethon::Curl).to receive(:slist_append).and_return(first, FFI::Pointer::NULL)
      expect(Ethon::Curl).to receive(:slist_free_all).with(first)

      expect { part.headers = ["X-First: 1", "X-Second: 2"] }.
        to raise_error(NoMemoryError, "curl_slist_append failed")
    end

    it "frees the generated header list when libcurl rejects it" do
      list = FFI::MemoryPointer.new(:int)
      allow(Ethon::Curl).to receive(:slist_append).and_return(list)
      allow(Ethon::Curl).to receive(:mime_headers).and_return(:out_of_memory)
      expect(Ethon::Curl).to receive(:slist_free_all).with(list)

      expect { part.headers = { "X-Test" => "1" } }.
        to raise_error(Ethon::Errors::Mime, /memory/i)
    end

    it "keeps a caller-owned header list alive until it is replaced" do
      list = Ethon::Curl::Slist.new(Ethon::Curl.slist_append(nil, "X-Test: 1"))
      part.headers = list
      expect(part.instance_variable_get(:@headers_list)).to be(list)

      allow(Ethon::Curl).to receive(:mime_headers).and_return(:out_of_memory)
      expect { part.headers = { "X-Other" => "2" } }.
        to raise_error(Ethon::Errors::Mime)
      expect(part.instance_variable_get(:@headers_list)).to be(list)
    end

    it "rejects a freed caller-owned header list" do
      list = Ethon::Curl::Slist.new(Ethon::Curl.slist_append(nil, "X-Test: 1"))
      list.free

      expect(Ethon::Curl).not_to receive(:mime_headers)
      expect { part.headers = list }.
        to raise_error(Ethon::Errors::EthonError, /freed/)
      expect(part.instance_variable_get(:@headers_list)).to be_nil
    end
  end

  describe "#initialize" do
    it "raises when the MIME API is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:mime_init).and_return(false)

      expect { described_class.new(easy) }.
        to raise_error(NotImplementedError, /curl_mime_init/)
    end

    it "rejects an Ethon::Multi" do
      multi = Ethon::Multi.new
      expect(Ethon::Curl).not_to receive(:mime_init)

      expect { described_class.new(multi) }.
        to raise_error(TypeError, /Ethon::Easy/)
    ensure
      multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
    end

    it "rejects a nil handle" do
      expect(Ethon::Curl).not_to receive(:mime_init)

      expect { described_class.new(nil) }.to raise_error(TypeError, /Ethon::Easy/)
    end

    it "rejects another object with a handle method" do
      handle_owner = Object.new
      def handle_owner.handle
        FFI::Pointer.new(1)
      end

      expect(Ethon::Curl).not_to receive(:mime_init)

      expect { described_class.new(handle_owner) }.
        to raise_error(TypeError, /Ethon::Easy/)
    end

    it "rejects a null easy handle pointer" do
      expect(Ethon::Curl).not_to receive(:mime_init)

      expect { described_class.new(FFI::Pointer::NULL) }.
        to raise_error(ArgumentError, /null easy handle/)
    end

    it "accepts a raw easy handle" do
      handle = Ethon::Curl.easy_init
      mime = described_class.new(handle)

      expect(mime).to be_a(described_class)
    ensure
      mime.free if mime
      Ethon::Curl.easy_cleanup(handle) if handle
    end

    it "accepts an owned easy handle" do
      mime = described_class.new(easy.handle)

      expect(mime).to be_a(described_class)
    ensure
      mime.free if mime
      easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
    end
  end

  describe "Easy integration" do
    let(:mime) { described_class.new(easy) }

    it "retains the MIME structure on the Easy" do
      easy.mime = mime

      expect(easy.mime).to be(mime)
      expect(easy.instance_variable_get(:@mime)).to be(mime)
    end

    it "clears the MIME structure" do
      easy.mime = mime

      easy.mime = nil

      expect(easy.mime).to be_nil
    end

    it "rejects another owned pointer type" do
      easy
      list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))
      expect(Ethon::Curl).not_to receive(:set_option)

      expect { easy.mime = list }.
        to raise_error(TypeError, /Ethon::Curl::Mime/)
      expect(easy.mime).to be_nil
    ensure
      list.free if list
    end

    it "rejects a raw pointer" do
      list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))

      expect { easy.mime = FFI::Pointer.new(list.address) }.
        to raise_error(TypeError, /Ethon::Curl::Mime/)
    ensure
      list.free if list
    end

    it "keeps the MIME structure when the replacement is rejected" do
      easy.mime = mime

      expect { easy.mime = "" }.
        to raise_error(TypeError, /Ethon::Curl::Mime/)
      expect(easy.mime).to be(mime)
    end

    it "posts a file part" do
      Tempfile.create do |file|
        file.write("mime content")
        file.flush

        easy.url = "http://localhost:3001/file"
        part = mime.addpart
        part.name = "file"
        part.file = file.path
        easy.mime = mime

        expect(easy.perform).to eq(:ok)
        body = JSON.parse(easy.response_body)
        expect(body["filename"]).to eq(File.basename(file.path))
        expect(body["content"]).to eq("mime content")
      end
    end

    it "rejects a form filename containing CRLF" do
      Tempfile.create("mime") do |file|
        form = Ethon::Easy::Form.new(easy, { :file => file })
        allow(form).to receive(:file_info).and_return(
          Ethon::Easy::Queryable::FileInfo.new(
            "file\r\nX-Injected: true",
            "text/plain",
            file.path
          )
        )

        expect { form.mime }.
          to raise_error(Ethon::Errors::InvalidValue, /filename/)
      end
    end

    it "posts a data part" do
      easy.url = "http://localhost:3001/"
      part = mime.addpart
      part.name = "field"
      part.data = "value"
      easy.mime = mime

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include("field")
      expect(easy.response_body).to include("value")
    end

    it "encodes a data part" do
      easy.url = "http://localhost:3001/"
      part = mime.addpart
      part.name = "field"
      part.data = "hello"
      part.encoder = "base64"
      easy.mime = mime

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include("aGVsbG8=")
    end

    it "posts a part with extra headers" do
      easy.url = "http://localhost:3001/"
      part = mime.addpart
      part.name = "field"
      part.data = "value"
      part.headers = { "X-Test" => "1" }
      easy.mime = mime

      expect(easy.perform).to eq(:ok)
    end

    it "clears the MIME structure on reset" do
      easy.mime = mime

      easy.reset

      expect(easy.mime).to be_nil
    end

    it "clears a previous MIME body when setting up an empty request" do
      easy.mime = mime
      post = Ethon::Easy::Http::Post.new("http://localhost:3001/", {})

      post.setup(easy)

      expect(easy.mime).to be_nil
    end

    it "resets the method after clearing a MIME body on a reused handle" do
      easy.mime = mime
      easy.http_request("http://localhost:3001/", :get, {})

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
    end

    it "rejects a MIME structure created before fork" do
      allow(mime).to receive(:check_pid!).and_raise(Ethon::Errors::ForkSafety.new)

      expect { easy.mime = mime }.to raise_error(Ethon::Errors::ForkSafety)
    end
  end
end
