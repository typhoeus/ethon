# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy do
  describe "#postfields=" do
    let(:easy) { Ethon::Easy.new }
    let(:body) { "a=1" }

    it "retains the string libcurl references" do
      easy.postfields = body

      retained = easy.instance_variable_get(:@postfields)
      expect(retained).to eq(body)
      expect(retained).to be_frozen
    end

    it "snapshots a mutable string so later mutations cannot invalidate it" do
      mutable = String.new("a=1")

      easy.postfields = mutable

      retained = easy.instance_variable_get(:@postfields)
      expect(retained).to eq("a=1")
      expect(retained).to be_frozen
      expect(retained).not_to be(mutable)
    end

    it "does not send later mutations of the caller's string" do
      easy.url = "http://localhost:3001/echo"
      source = String.new("first")
      easy.postfields = source
      easy.postfieldsize = 5
      source.replace("other")

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("first")
    end

    it "does not read freed memory when the caller's string grows" do
      easy.url = "http://localhost:3001/echo"
      source = String.new("a")
      easy.postfields = source
      easy.postfieldsize = 1
      source << "b" * 100_000

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("a")
    end

    it "clears the retained string on reset" do
      easy.postfields = body

      easy.reset

      expect(easy.instance_variable_get(:@postfields)).to be_nil
    end

    it "sends embedded null bytes with the explicit body length" do
      payload = "\x00binary\x00body".b
      easy.url = "http://localhost:3001/echo"
      easy.postfields = payload

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq(payload)
    end

    it "retains a binary body exactly as it was accepted" do
      payload = "a\0b".b

      easy.postfields = payload

      retained = easy.instance_variable_get(:@postfields)
      expect(retained).to eq(payload)
      expect(retained.bytesize).to eq(3)
    end

    it "sets the body size from the retained bytes" do
      expect(Ethon::Curl).to receive(:set_option).with(:postfields, kind_of(::FFI::MemoryPointer), easy.handle)
      expect(Ethon::Curl).to receive(:set_option).with(:postfieldsize, 5, easy.handle)

      easy.postfields = "hello"
    end

    it "keeps the native body buffer alive" do
      easy.postfields = "hello"

      pointer = easy.instance_variable_get(:@postfields_pointer)
      expect(pointer).to be_a(::FFI::MemoryPointer)
      expect(pointer.read_string).to eq("hello")
    end

    it "does not reuse a previous request's body size" do
      easy.http_request("http://localhost:3001/echo", :post, :body => "0123456789")
      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("0123456789")

      easy.postfields = "hi"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("hi")
    end

    it "clears a previous form body size" do
      easy.http_request("http://localhost:3001/echo", :post, :body => "0123456789")

      easy.postfields = nil
      easy.copypostfields = "hi"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("hi")
    end

    it "rejects a postfieldsize larger than the retained body" do
      easy.postfields = "abc"

      expect { easy.postfieldsize = 4 }.
        to raise_error(Ethon::Errors::InvalidValue, /postfieldsize/)
    end

    it "rejects a large postfieldsize larger than the retained body" do
      easy.postfields = "abc"

      expect { easy.postfieldsize_large = 4 }.
        to raise_error(Ethon::Errors::InvalidValue, /postfieldsize_large/)
    end

    it "still allows an explicit prefix of the retained body" do
      easy.url = "http://localhost:3001/echo"
      easy.postfields = "abcdef"
      easy.postfieldsize = 3

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("abc")
    end

    it "replaces a body whose size still describes the previous body" do
      easy.url = "http://localhost:3001/echo"
      easy.postfields = "abcdef"
      easy.copypostfields = "xy"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("xy")
    end

    it "replaces an inherited size when the copied body is longer" do
      easy.url = "http://localhost:3001/echo"
      easy.postfields = "abc"
      easy.copypostfields = "abcdef"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("abcdef")
    end

    it "clears the copied body size" do
      easy.url = "http://localhost:3001/echo"
      easy.copypostfields = "abc"
      easy.copypostfields = nil

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("")
    end

    it "rejects a copied body that is larger than an explicit size" do
      easy.postfieldsize = 5

      expect { easy.copypostfields = "xy" }.
        to raise_error(Ethon::Errors::InvalidValue, /copypostfields/)
    end

    it "keeps an explicit prefix when copying a body" do
      easy.url = "http://localhost:3001/echo"
      easy.postfieldsize = 2
      easy.copypostfields = "hello"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("he")
    end

    it "copies null bytes with the exact body length" do
      payload = "a\0b".b
      easy.url = "http://localhost:3001/echo"
      easy.copypostfields = payload

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq(payload)
    end
  end
end
