# frozen_string_literal: true
require 'spec_helper'
require 'stringio'
require 'tempfile'

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

  it "does not copy the destination when duplicating an Easy" do
    io = StringIO.new
    easy.file = io

    copy = easy.dup

    expect(copy.instance_variable_get(:@response_body_io)).to be_nil
    expect(copy.response_body).to eq("")
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

  it "propagates write errors" do
    io = Object.new
    io.define_singleton_method(:write) { |_| raise IOError, "disk full" }
    easy.file = io

    expect { easy.perform }.to raise_error(IOError, "disk full")
  end
end
