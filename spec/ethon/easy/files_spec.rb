# frozen_string_literal: true
require 'spec_helper'
require 'stringio'
require 'tempfile'
require 'pathname'
require 'tmpdir'

describe Ethon::Easy::Files do
  let(:easy) { Ethon::Easy.new(url: "http://localhost:3001/") }

  [:file, :writedata].each do |option|
    describe "##{option}=" do
      it "streams the response to a path" do
        Tempfile.create do |file|
          file.close
          easy.public_send("#{option}=", file.path)

          expect(easy.perform).to eq(:ok)
          expect(File.binread(file.path)).to include('"REQUEST_METHOD":"GET"')
          expect(easy.response_body).to be_nil
        end
      end

      it "streams the response to a caller-owned IO" do
        io = StringIO.new
        easy.public_send("#{option}=", io)

        expect(easy.perform).to eq(:ok)
        expect(io.string).to include('"REQUEST_METHOD":"GET"')
        expect(io).not_to be_closed
      end
    end
  end

  it "flushes a path destination before on_complete" do
    Tempfile.create do |file|
      file.close
      seen = nil
      easy.url = "http://localhost:3001/binary/1000"
      easy.file = file.path
      easy.on_complete { seen = File.binread(file.path).bytesize }

      expect(easy.perform).to eq(:ok)
      expect(seen).to eq(1000)
    end
  end

  it "flushes a caller-owned file before on_complete" do
    Tempfile.create do |file|
      file.binmode
      seen = nil
      easy.url = "http://localhost:3001/binary/1000"
      easy.file = file
      easy.on_complete { seen = File.binread(file.path).bytesize }

      expect(easy.perform).to eq(:ok)
      expect(seen).to eq(1000)
      expect(file).not_to be_closed
      expect(File.binread(file.path).bytesize).to eq(1000)
    end
  end

  it "flushes a caller-owned file before a Multi completion" do
    Tempfile.create do |file|
      file.binmode
      seen = nil
      easy.url = "http://localhost:3001/binary/1000"
      easy.file = file
      easy.on_complete { seen = File.binread(file.path).bytesize }
      multi = Ethon::Multi.new
      multi.add(easy)

      expect { multi.perform }.not_to raise_error
      expect(seen).to eq(1000)
      expect(File.binread(file.path).bytesize).to eq(1000)
    ensure
      multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
    end
  end

  it "streams the response to a path-like object" do
    Tempfile.create do |file|
      file.close
      path = Struct.new(:to_path).new(file.path)
      easy.file = path

      expect(easy.perform).to eq(:ok)
      expect(File.binread(file.path)).to include('"REQUEST_METHOD":"GET"')
    end
  end

  it "treats a writable path-like object such as Pathname as a path" do
    Tempfile.create do |file|
      file.close
      size = 20_000
      pattern = (0..255).to_a.pack("C*")
      expected = (pattern * (size / pattern.bytesize + 1)).byteslice(0, size)
      easy.url = "http://localhost:3001/binary/#{size}"
      easy.file = Pathname.new(file.path)

      expect(easy.perform).to eq(:ok)
      expect(File.binread(file.path)).to eq(expected)
    end
  end

  it "closes an owned file when a callback raises" do
    Tempfile.create do |file|
      file.close
      easy.file = file.path
      io = easy.instance_variable_get(:@response_body_io)
      easy.on_body { raise "callback failed" }

      expect { easy.perform }.to raise_error("callback failed")
      expect(io).to be_closed
    end
  end

  it "closes an owned file when on_complete raises" do
    Tempfile.create do |file|
      file.close
      easy.file = file.path
      io = easy.instance_variable_get(:@response_body_io)
      easy.on_complete { raise "complete failed" }

      expect { easy.perform }.to raise_error("complete failed")
      expect(io).to be_closed
    end
  end

  it "closes an owned file on reset" do
    Tempfile.create do |file|
      file.close
      easy.file = file.path
      io = easy.instance_variable_get(:@response_body_io)

      easy.reset

      expect(io).to be_closed
      expect(easy.response_body).to eq("")
    end
  end

  it "leaves reset state intact when closing an owned file fails" do
    Tempfile.create do |file|
      file.close
      easy.url = "http://localhost:3001/"
      easy.postfields = "body"
      easy.file = file.path
      io = easy.instance_variable_get(:@response_body_io)
      allow(io).to receive(:close).and_raise(IOError, "close failed")

      expect { easy.reset }.to raise_error(IOError, "close failed")
      expect(easy.url).to eq("http://localhost:3001/")
      expect(easy.instance_variable_get(:@postfields)).to eq("body")
      expect(easy.instance_variable_get(:@response_body_io)).to be(io)

      allow(io).to receive(:close).and_call_original
      expect { easy.reset }.not_to raise_error
      expect(easy.url).to be_nil
      expect(easy.instance_variable_get(:@postfields)).to be_nil
    end
  end

  it "does not copy the destination when duplicating an Easy" do
    io = StringIO.new
    easy.file = io

    copy = easy.dup

    expect(copy.instance_variable_get(:@response_body_io)).to be_nil
    expect(copy.response_body).to eq("")
  end

  it "keeps a path destination on a duplicate and opens its own stream" do
    Tempfile.create do |file|
      file.close
      easy.url = "http://localhost:3001/binary/1000"
      easy.file = file.path

      copy = easy.dup

      expect(copy.instance_variable_get(:@response_body_path)).to eq(file.path)
      expect(copy.instance_variable_get(:@response_body_io)).to be_nil

      expect(copy.perform).to eq(:ok)

      expect(copy.response_body).to be_nil
      expect(File.binread(file.path).bytesize).to eq(1000)
    ensure
      copy.cleanup if copy && !copy.instance_variable_get(:@cleaned_up)
      easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
    end
  end

  it "restores in-memory buffering when cleared" do
    easy.file = StringIO.new

    easy.file = nil
    easy.perform

    expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
  end

  it "reopens a path for a reused Easy" do
    Tempfile.create do |file|
      file.close
      easy.file = file.path

      2.times { expect(easy.perform).to eq(:ok) }

      expect(File.binread(file.path)).to include('"REQUEST_METHOD":"GET"')
    end
  end

  it "keeps the previous destination when a new path cannot be opened" do
    Dir.mktmpdir do |dir|
      good = File.join(dir, "good")
      missing = File.join(dir, "missing", "out")
      easy = Ethon::Easy.new(:url => "http://localhost:3001/binary/8", :file => good)
      previous_io = easy.instance_variable_get(:@response_body_io)

      expect { easy.file = missing }.to raise_error(Errno::ENOENT)
      expect(easy.instance_variable_get(:@response_body_path)).to eq(good)
      expect(easy.instance_variable_get(:@response_body_io)).to be(previous_io)
      expect(previous_io).not_to be_closed

      expect(easy.perform).to eq(:ok)
      expect(File.binread(good).bytesize).to eq(8)
    end
  end

  it "closes an owned destination that a new path replaces" do
    Dir.mktmpdir do |dir|
      first = File.join(dir, "first")
      second = File.join(dir, "second")
      easy.file = first
      previous_io = easy.instance_variable_get(:@response_body_io)

      easy.file = second

      expect(previous_io).to be_closed
      expect(easy.instance_variable_get(:@response_body_path)).to eq(second)
    ensure
      easy.file = nil
    end
  end

  it "closes the new file when the previous destination cannot be released" do
    Dir.mktmpdir do |dir|
      first = File.join(dir, "first")
      second = File.join(dir, "second")
      easy.file = first
      previous_io = easy.instance_variable_get(:@response_body_io)
      allow(previous_io).to receive(:close).and_raise(IOError, "close failed")
      opened = nil
      allow(File).to receive(:open).and_wrap_original do |original, *args|
        opened = original.call(*args)
      end

      expect { easy.file = second }.to raise_error(IOError, "close failed")
      expect(easy.instance_variable_get(:@response_body_path)).to eq(first)
      expect(easy.instance_variable_get(:@response_body_io)).to be(previous_io)
      expect(opened).to be_closed
    ensure
      allow(previous_io).to receive(:close).and_call_original if previous_io
      allow(File).to receive(:open).and_call_original
      easy.file = nil
    end
  end

  it "propagates write errors" do
    io = Object.new
    io.define_singleton_method(:write) { |_| raise IOError, "disk full" }
    easy.file = io

    expect { easy.perform }.to raise_error(IOError, "disk full")
  end

  it "does not truncate a path when the handle has been cleaned up" do
    Tempfile.create do |file|
      file.write("existing content")
      file.flush
      path = file.path

      easy.cleanup

      expect { easy.file = path }.
        to raise_error(Ethon::Errors::EthonError, /cleaned up/)
      expect(File.read(path)).to eq("existing content")
    end
  end

  it "does not truncate a path when the handle was inherited across a fork" do
    Tempfile.create do |file|
      file.write("existing content")
      file.flush
      path = file.path

      allow(easy).to receive(:handle).and_raise(Ethon::Errors::ForkSafety.new)

      expect { easy.file = path }.to raise_error(Ethon::Errors::ForkSafety)
      expect(File.read(path)).to eq("existing content")
    end
  end

  describe "completion callbacks" do
    it "does not finish a destination installed by on_complete" do
      Tempfile.create do |file|
        file.close
        easy.file = file.path
        next_io = Object.new
        next_io.define_singleton_method(:write) { |_| }
        next_io.define_singleton_method(:flush) { raise IOError, "must not flush" }
        easy.on_complete { |e| e.file = next_io }

        expect(easy.perform).to eq(:ok)
      ensure
        easy.file = nil
      end
    end

    it "keeps a response file scheduled from on_complete open for a new Multi" do
      Dir.mktmpdir do |dir|
        first = File.join(dir, "first")
        second = File.join(dir, "second")
        multi = Ethon::Multi.new
        easy = Ethon::Easy.new(:url => "http://localhost:3001/first", :file => first)
        scheduled = false
        easy.on_complete do |e|
          next if scheduled

          scheduled = true
          e.url = "http://localhost:3001/second"
          e.file = second
          multi.add(e)
        end

        expect(easy.perform).to eq(:ok)
        expect { multi.perform }.not_to raise_error
        expect(File.binread(second)).to include('"PATH_INFO":"/second"')
      ensure
        multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
        easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
      end
    end

    it "keeps a response file scheduled from on_complete open for the same Multi" do
      Dir.mktmpdir do |dir|
        first = File.join(dir, "first")
        second = File.join(dir, "second")
        multi = Ethon::Multi.new
        easy = Ethon::Easy.new(:url => "http://localhost:3001/first", :file => first)
        multi.add(easy)
        scheduled = false
        easy.on_complete do |e|
          next if scheduled

          scheduled = true
          e.url = "http://localhost:3001/second"
          e.file = second
          multi.add(e)
        end

        expect { multi.perform }.not_to raise_error
        expect(File.binread(second)).to include('"PATH_INFO":"/second"')
      ensure
        multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
        easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
      end
    end

    it "reopens the same response file when on_complete schedules the next transfer" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "body")
        multi = Ethon::Multi.new
        easy = Ethon::Easy.new(:url => "http://localhost:3001/first", :file => path)
        scheduled = false
        easy.on_complete do |e|
          next if scheduled

          scheduled = true
          e.url = "http://localhost:3001/second"
          multi.add(e)
        end

        expect(easy.perform).to eq(:ok)
        expect { multi.perform }.not_to raise_error
        expect(File.binread(path)).to include('"PATH_INFO":"/second"')
      ensure
        multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
        easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
      end
    end

    it "raises a callback error before running a transfer scheduled by on_complete" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "body")
        multi = Ethon::Multi.new
        easy = Ethon::Easy.new(:url => "http://localhost:3001/first", :file => path)
        raised = false
        easy.on_body do |_chunk|
          next if raised

          raised = true
          raise "callback failed"
        end
        scheduled = false
        easy.on_complete do |e|
          next if scheduled

          scheduled = true
          e.url = "http://localhost:3001/second"
          multi.add(e)
        end

        expect { easy.perform }.to raise_error("callback failed")
        expect { multi.perform }.not_to raise_error
        expect(File.binread(path)).to include('"PATH_INFO":"/second"')
      ensure
        multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
        easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
      end
    end
  end

  describe "failing response stream teardown" do
    it "keeps the body callback error when closing the response file fails" do
      Tempfile.create do |file|
        file.close
        easy.file = file.path
        io = easy.instance_variable_get(:@response_body_io)
        allow(io).to receive(:close).and_raise(IOError, "close failed")
        easy.on_body { raise "callback failed" }

        expect { easy.perform }.to raise_error("callback failed")
      ensure
        allow(io).to receive(:close).and_call_original if io
        easy.file = nil
      end
    end

    it "keeps the on_complete error when closing the response file fails" do
      Tempfile.create do |file|
        file.close
        easy.file = file.path
        io = easy.instance_variable_get(:@response_body_io)
        allow(io).to receive(:close).and_raise(IOError, "close failed")
        easy.on_complete { raise "complete failed" }

        expect { easy.perform }.to raise_error("complete failed")
      ensure
        allow(io).to receive(:close).and_call_original if io
        easy.file = nil
      end
    end

    it "keeps the body callback error when flushing the response IO fails" do
      io = Object.new
      io.define_singleton_method(:write) { |_| }
      io.define_singleton_method(:flush) { raise IOError, "flush failed" }
      easy.file = io
      easy.on_body { raise "callback failed" }

      expect { easy.perform }.to raise_error("callback failed")
    end

    it "raises a close error after a successful transfer" do
      Tempfile.create do |file|
        file.close
        easy.file = file.path
        io = easy.instance_variable_get(:@response_body_io)
        allow(io).to receive(:close).and_raise(IOError, "close failed")

        expect { easy.perform }.to raise_error(IOError, "close failed")
      ensure
        allow(io).to receive(:close).and_call_original if io
        easy.file = nil
      end
    end
  end
end
