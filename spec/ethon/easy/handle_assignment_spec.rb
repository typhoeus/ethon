# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe "assigning an Easy handle" do
  let(:url) { "http://localhost:3001/" }

  describe "a handle passed to the constructor" do
    it "collects the response body and headers" do
      easy = Ethon::Easy.new(:handle => Ethon::Curl.easy_init, :url => url)

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
      expect(easy.response_headers).to include("HTTP/1.1 200")
    end

    it "applies the other constructor options to the supplied handle" do
      easy = Ethon::Easy.new(
        :handle => Ethon::Curl.easy_init,
        :url => "#{url}from-constructor"
      )

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"PATH_INFO":"/from-constructor"')
    end

    it "accepts the handle under a string key" do
      easy = Ethon::Easy.new(
        "handle" => Ethon::Curl.easy_init,
        "url" => "#{url}string-key"
      )

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"PATH_INFO":"/string-key"')
    end

    it "still installs a callback passed alongside the handle" do
      received = String.new
      easy = Ethon::Easy.new(
        :handle => Ethon::Curl.easy_init,
        :url => url,
        :writefunction => proc do |stream, size, num, _|
          received << stream.read_string(size * num)
          size * num
        end
      )

      expect(easy.perform).to eq(:ok)
      expect(received).to include('"REQUEST_METHOD":"GET"')
      expect(easy.response_body).to be_empty
    end
  end

  describe "clearing the handle" do
    it "collects the next response on the new handle" do
      easy = Ethon::Easy.new
      old_handle = easy.handle

      easy.handle = nil
      easy.url = url

      expect(easy.handle).not_to be(old_handle)
      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
      expect(easy.response_headers).to include("HTTP/1.1 200")
    end
  end

  describe "replacing the handle" do
    it "collects the next response on the replacement" do
      easy = Ethon::Easy.new(:url => url)

      easy.handle = Ethon::Curl.easy_init
      easy.url = url

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
    end

    it "replays retained request callbacks" do
      received = String.new
      easy = Ethon::Easy.new
      easy.writefunction = proc do |stream, size, num, _|
        received << stream.read_string(size * num)
        size * num
      end

      easy.handle = Ethon::Curl.easy_init
      easy.url = url

      expect(easy.perform).to eq(:ok)
      expect(received).to include('"REQUEST_METHOD":"GET"')
    end

    it "replays a retained request body callback" do
      easy = Ethon::Easy.new
      easy.set_read_callback("abc")

      easy.handle = Ethon::Curl.easy_init
      easy.upload = true
      easy.infilesize = 3
      easy.url = "#{url}echo"

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq("abc")
    end

    it "leaves the handle and its callbacks alone when reassigned" do
      easy = Ethon::Easy.new
      handle = easy.handle

      expect(Ethon::Curl).not_to receive(:set_option)
      easy.handle = handle

      expect(easy.handle).to be(handle)
    end

    it "frees the handle it replaces" do
      easy = Ethon::Easy.new
      old_handle = easy.handle
      address = old_handle.address

      easy.handle = Ethon::Curl.easy_init

      expect { old_handle.check_pid! }.
        to raise_error(Ethon::Errors::EthonError, /freed/)
      expect(Ethon::Curl::OwnedPointer.owners).not_to have_key(address)
    end

    it "frees the handle when assigning nil" do
      easy = Ethon::Easy.new
      old_handle = easy.handle

      easy.handle = nil

      expect { old_handle.check_pid! }.
        to raise_error(Ethon::Errors::EthonError, /freed/)
    end

    it "does not free a handle owned by another Easy" do
      easy = Ethon::Easy.new(:url => url)
      copy = easy.dup

      expect { easy.perform }.not_to raise_error
      expect(easy.return_code).to eq(:ok)
      expect(copy.perform).to eq(:ok)
    end

    it "reattaches the error buffer to the replacement" do
      easy = Ethon::Easy.new
      easy.errorbuffer = true
      buffer = easy.instance_variable_get(:@error_buffer)
      old_handle = easy.handle

      easy.handle = Ethon::Curl.easy_init
      easy.url = "#{url}redirect"
      easy.followlocation = true
      easy.maxredirs = 0

      expect(easy.handle.error_buffer).to be(buffer)
      expect(easy.perform).to eq(:too_many_redirects)
      expect(easy.error_message).to match(/redirect/i)
      expect { old_handle.check_pid! }.
        to raise_error(Ethon::Errors::EthonError, /freed/)
    end

    it "keeps on_progress callbacks firing after replacing the handle" do
      easy = Ethon::Easy.new
      calls = 0
      easy.on_progress { calls += 1 }

      easy.handle = Ethon::Curl.easy_init
      easy.url = "#{url}binary/16384"

      expect(easy.perform).to eq(:ok)
      expect(calls).to be > 0
    end

    it "keeps an explicitly enabled progress callback working" do
      easy = Ethon::Easy.new
      calls = 0
      easy.noprogress = 0
      easy.xferinfofunction = proc { |*| calls += 1; 0 }

      easy.handle = Ethon::Curl.easy_init
      easy.url = "#{url}binary/16384"

      expect(easy.perform).to eq(:ok)
      expect(calls).to be > 0
    end
  end
end
