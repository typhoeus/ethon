# frozen_string_literal: true
require 'spec_helper'
require 'stringio'

describe Ethon::Easy::Callbacks do
  let!(:easy) { Ethon::Easy.new }

  describe "#set_callbacks" do
    before do
      expect(Ethon::Curl).to receive(:set_option).exactly(3).times
    end

    it "sets write-, debug-, and headerfunction" do
      easy.set_callbacks
    end

    it "resets @response_body" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@response_body)).to eq("")
    end

    it "resets @response_headers" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@response_headers)).to eq("")
    end

    it "resets @debug_info" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@debug_info).to_a).to eq([])
    end

    it "keeps the response body unbuffered when streaming to an IO" do
      easy.file = StringIO.new

      easy.set_callbacks

      expect(easy.response_body).to be_nil
    end
  end

  describe "#progress_callback" do
    it "returns 0" do
      expect(easy.progress_callback.call(0,1,1,1,1)).to be(0)
    end
  end

  describe "#body_write_callback" do
    let(:body_write_callback) { easy.instance_variable_get(:@body_write_callback) }
    let(:stream) { double(:read_string => "") }
    context "when body returns not :abort" do
      it "returns number bigger than 0" do
        expect(body_write_callback.call(stream, 1, 1, nil) > 0).to be(true)
      end
    end

    context "when body returns :abort" do
      before do
        easy.on_body.clear
        easy.on_body { :abort }
      end
      let(:body_write_callback) { easy.instance_variable_get(:@body_write_callback) }

      it "returns -1 to indicate abort to libcurl" do
        expect(body_write_callback.call(stream, 1, 1, nil)).to eq(-1)
      end
    end
  end

  describe "#header_write_callback" do
    let(:header_write_callback) { easy.instance_variable_get(:@header_write_callback) }
    let(:stream) { double(:read_string => "") }
    context "when header returns not :abort" do
      it "returns number bigger than 0" do
        expect(header_write_callback.call(stream, 1, 1, nil) > 0).to be(true)
      end
    end

    context "when streaming to an IO and the headers abort" do
      before do
        easy.url = "http://localhost:3001/"
        easy.file = StringIO.new
        easy.on_headers.clear
        easy.on_headers { :abort }
      end

      it "aborts without raising a NoMethodError" do
        expect { easy.perform }.not_to raise_error
        expect(easy.return_code).to eq(:write_error)
      end
    end

    context "when appending a header raises" do
      before do
        headers = Object.new
        def headers.<<(*)
          raise "header failure"
        end
        easy.response_headers = headers
      end

      it "returns 0 and re-raises after the transfer" do
        expect(header_write_callback.call(stream, 1, 1, nil)).to eq(0)
        expect { easy.raise_callback_error }.to raise_error("header failure")
      end
    end

    context "when header returns :abort" do
      before do
        easy.on_headers.clear
        easy.on_headers { :abort }
      end
      let(:body_write_callback) { easy.instance_variable_get(:@body_write_callback) }
      # on_headers callbacks are expected to be called exactly one time, once all headers are in.
      # We can't abort exactly on receiving the headers, as we might need to follow redirects,
      # so we do the next best thing, which is aborting on the first body chunk.
      it "returns -1 to indicate abort to libcurl" do
        expect(body_write_callback.call(stream, 1, 1, nil)).to eq(-1)
      end
    end
  end

  describe "#debug_callback" do
    let(:callback) { easy.send(:debug_callback) }
    let(:data) { double(:read_string => "message") }

    it "prints SSL data as a byte count" do
      expect {
        callback.call(easy.handle, :ssl_data_in, data, 7, nil)
      }.to output("[7 bytes data]\n").to_stdout
    end

    it "does not print raw data transfers" do
      expect {
        callback.call(easy.handle, :data_in, data, 7, nil)
      }.not_to output.to_stdout
    end

    it "prints all other debug messages" do
      expect {
        callback.call(easy.handle, :text, data, 7, nil)
      }.to output("message").to_stdout
    end
  end

  describe "#set_progress_callback" do
    it "uses xferinfo on libcurl 7.32.0 and newer" do
      expect(Ethon::Curl).to receive(:version_info).and_return({ :version_num => 0x072000 })
      expect(Ethon::Curl).to receive(:set_option).
        with(:xferinfofunction, easy.progress_callback, easy.handle)

      easy.send(:set_progress_callback)
    end

    it "uses the double-based progress callback before 7.32.0" do
      expect(Ethon::Curl).to receive(:version_info).and_return({ :version_num => 0x070908 })
      expect(Ethon::Curl).to receive(:set_option).
        with(:progressfunction, easy.progress_callback, easy.handle)

      easy.send(:set_progress_callback)
    end
  end

  describe "#set_read_callback" do
    let(:stream) { double(:written => []) }

    before do
      allow(stream).to receive(:write_string) do |chunk, size|
        stream.written << [chunk, size]
      end
    end

    it "exposes the installed callback" do
      easy.set_read_callback("body")

      expect(easy.read_callback).to be_a(Proc)
    end

    it "reads a string body and reports EOF" do
      easy.set_read_callback("abc")
      callback = easy.read_callback

      expect(callback.call(stream, 16, 1, nil)).to eq(3)
      expect(callback.call(stream, 16, 1, nil)).to eq(0)
      expect(stream.written).to eq([["abc", 3]])
    end

    it "rewinds a seekable body when the transfer state resets" do
      body = StringIO.new("abc")
      easy.set_read_callback(body)

      expect(easy.read_callback.call(stream, 16, 1, nil)).to eq(3)
      expect(body.pos).to eq(3)

      easy.reset_transfer_state

      expect(body.pos).to eq(0)
      expect(easy.read_callback.call(stream, 16, 1, nil)).to eq(3)
    end

    it "reports the number of bytes actually read from short-reading IOs" do
      body = Class.new do
        def initialize
          @data = "abcdef"
          @pos = 0
        end

        def size
          @data.bytesize
        end

        def pos
          @pos
        end

        def read(length)
          chunk = @data[@pos, [length, 2].min]
          @pos += chunk.bytesize
          chunk
        end
      end.new

      easy.set_read_callback(body)
      callback = easy.read_callback

      expect(callback.call(stream, 16, 1, nil)).to eq(2)
      expect(callback.call(stream, 16, 1, nil)).to eq(2)
      expect(callback.call(stream, 16, 1, nil)).to eq(2)
      expect(callback.call(stream, 16, 1, nil)).to eq(0)
      expect(stream.written.map(&:first).join).to eq("abcdef")
    end

    it "starts at the current position of a File" do
      File.open(__FILE__) do |file|
        file.read(3)
        easy.set_read_callback(file)
        callback = easy.read_callback

        expected = File.read(__FILE__)[3, 2]

        expect(callback.call(stream, 2, 1, nil)).to eq(2)
        expect(stream.written).to eq([[expected, 2]])
      end
    end

    it "reads from indexable bodies" do
      body = Class.new do
        def size
          6
        end

        def [](offset, length)
          "abcdef"[offset, length]
        end
      end.new

      easy.set_read_callback(body)
      callback = easy.read_callback

      expect(callback.call(stream, 16, 1, nil)).to eq(6)
      expect(callback.call(stream, 16, 1, nil)).to eq(0)
      expect(stream.written).to eq([["abcdef", 6]])
    end

    it "reads from indexable bodies without a size" do
      body = Class.new do
        def [](offset, length)
          "xyz"[offset, length]
        end
      end.new

      easy.set_read_callback(body)
      callback = easy.read_callback

      expect(callback.call(stream, 16, 1, nil)).to eq(3)
      expect(callback.call(stream, 16, 1, nil)).to eq(0)
      expect(stream.written).to eq([["xyz", 3]])
    end

    it "captures read errors and reports them after the transfer" do
      body = Object.new
      def body.read(*)
        raise IOError, "read failed"
      end

      easy.set_read_callback(body)

      expect(easy.read_callback.call(stream, 16, 1, nil)).to eq(0)
      expect { easy.raise_callback_error }.to raise_error(IOError, "read failed")
    end
  end
end
