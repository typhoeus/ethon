# frozen_string_literal: true
require 'spec_helper'

describe "writing a response body to an IO" do
  let(:easy) { Ethon::Easy.new }

  it "writes the complete chunk when the destination accepts short writes" do
    writer = Class.new do
      attr_reader :string

      def initialize
        @string = String.new.b
      end

      def write(data)
        piece = data.byteslice(0, 7)
        @string << piece
        piece.bytesize
      end

      def flush; end
    end.new
    pattern = (0..255).to_a.pack("C*")
    expected = (pattern * (1024 / pattern.bytesize + 1)).byteslice(0, 1024)
    easy.url = "http://localhost:3001/binary/1024"
    easy.file = writer

    expect(easy.perform).to eq(:ok)
    expect(writer.string).to eq(expected)
  end

  it "raises when a response write makes no progress" do
    writer = Object.new
    writer.define_singleton_method(:write) { |_| 0 }
    writer.define_singleton_method(:flush) {}
    easy.url = "http://localhost:3001/binary/8"
    easy.file = writer

    expect { easy.perform }.to raise_error(IOError, /made no progress/)
  end
end
