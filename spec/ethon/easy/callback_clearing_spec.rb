# frozen_string_literal: true
require 'spec_helper'
require 'tempfile'

describe "clearing Easy callbacks" do
  let(:easy) { Ethon::Easy.new }
  let(:size) { 16_384 }
  let(:url) { "http://localhost:3001/binary/#{size}" }
  let(:payload) do
    pattern = (0..255).to_a.pack("C*")
    (pattern * (size / pattern.bytesize + 1)).byteslice(0, size)
  end

  describe "#writefunction=" do
    it "restores Ethon's body callback when set to nil" do
      easy.writefunction = proc { |stream, size, num, _| stream.read_string(size * num).bytesize }

      easy.writefunction = nil
      easy.url = url

      expect(easy.perform).to eq(:ok)
      expect(easy.response_body).to eq(payload)
    end

    it "does not retain Ethon's internal callback as a caller callback" do
      easy.writefunction = proc {}
      easy.writefunction = nil

      expect(easy.instance_variable_get(:@procs)).not_to have_key(:writefunction)
    end

    it "does not fall back to libcurl's stdout writer" do
      original_stdout = STDOUT.dup
      Tempfile.create("ethon-stdout") do |output|
        result = nil
        error = nil

        begin
          easy.writefunction = proc { |stream, size, num, _| stream.read_string(size * num).bytesize }
          easy.writefunction = nil
          easy.url = url

          STDOUT.reopen(output)
          begin
            result = easy.perform
          rescue Exception => e
            error = e
          ensure
            STDOUT.reopen(original_stdout)
          end
        ensure
          original_stdout.close
        end

        output.rewind
        expect(error).to be_nil
        expect(result).to eq(:ok)
        expect(output.read).to eq("")
        expect(easy.response_body).to eq(payload)
      end
    end

    it "still installs a custom callback assigned afterwards" do
      received = String.new
      easy.writefunction = nil
      easy.writefunction = proc do |stream, size, num, _|
        received << stream.read_string(size * num)
        size * num
      end
      easy.url = url

      expect(easy.perform).to eq(:ok)
      expect(received.bytesize).to eq(payload.bytesize)
      expect(easy.response_body).to be_empty
    end
  end

  describe "#headerfunction=" do
    it "restores Ethon's header callback when set to nil" do
      easy.headerfunction = proc { |*| 0 }

      easy.headerfunction = nil
      easy.url = url

      expect(easy.perform).to eq(:ok)
      expect(easy.response_headers).to include("HTTP/1.1 200")
    end

    it "keeps the body callback and the header callback independent" do
      easy.headerfunction = proc { |*| 0 }
      easy.writefunction = proc { |*| 0 }

      easy.headerfunction = nil
      easy.writefunction = nil
      easy.url = url

      expect(easy.perform).to eq(:ok)
      expect(easy.response_headers).to include("HTTP/1.1 200")
      expect(easy.response_body).to eq(payload)
    end
  end

  describe "#debugfunction=" do
    it "restores Ethon's debug callback when set to nil" do
      easy.verbose = true
      easy.debugfunction = proc { |*| }

      easy.debugfunction = nil
      easy.url = url

      expect(easy.perform).to eq(:ok)
      expect(easy.debug_info.text).not_to be_empty
      expect(easy.debug_info.header_in).not_to be_empty
    end
  end

  describe "duplicating after clearing a callback" do
    it "installs a callback that belongs to the duplicate" do
      easy.writefunction = proc {}
      easy.writefunction = nil
      easy.url = url

      copy = easy.dup

      expect(copy.perform).to eq(:ok)
      expect(copy.response_body).to eq(payload)
    end
  end
end
