# frozen_string_literal: true
require 'spec_helper'
require 'stringio'

describe "verbose debug output" do
  let(:url) { "http://localhost:3001/" }
  let(:log_io) { StringIO.new }
  let(:logger) { Logger.new(log_io).tap { |log| log.level = Logger::DEBUG } }

  around do |example|
    original = Ethon.logger
    Ethon.logger = logger
    example.run
  ensure
    Ethon.logger = original
  end

  it "logs libcurl's debug messages through Ethon.logger" do
    easy = Ethon::Easy.new(:url => url, :verbose => true)

    expect { easy.perform }.not_to output.to_stdout
    expect(log_io.string).to include("GET / HTTP/1.1")
  end

  it "does not log body data" do
    easy = Ethon::Easy.new(:url => url, :verbose => true)

    easy.perform

    expect(log_io.string).not_to include('"REQUEST_METHOD"')
  end

  it "logs nothing when the logger is not at the debug level" do
    logger.level = Logger::INFO
    easy = Ethon::Easy.new(:url => url, :verbose => true)

    expect { easy.perform }.not_to output.to_stdout
    expect(log_io.string).to be_empty
  end

  it "still collects the debug info" do
    easy = Ethon::Easy.new(:url => url, :verbose => true)

    easy.perform

    expect(easy.debug_info.header_out.join).to include("GET / HTTP/1.1")
    expect(easy.debug_info.header_in.join).to include("HTTP/1.1 200 OK")
  end

  it "still calls the debugfunction observer" do
    types = []
    easy = Ethon::Easy.new(:url => url, :verbose => true)
    easy.debugfunction { |_handle, type, _data, _size, _udata| types << type }

    easy.perform

    expect(types).to include(:header_out, :header_in)
  end
end
