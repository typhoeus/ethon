# frozen_string_literal: true
require 'spec_helper'
require 'json'
require 'tmpdir'

describe "GC safety" do
  let(:url) { "http://localhost:3001/" }

  it "keeps the body callback alive during the transfer" do
    chunks = []
    easy = Ethon::Easy.new(:url => url)
    easy.on_body do |chunk|
      GC.start
      chunks << chunk
    end
    GC.start

    expect(easy.perform).to eq(:ok)
    expect(chunks.join).to include('"REQUEST_METHOD":"GET"')
    expect(easy.response_body).to be_empty
  end

  it "keeps a custom write callback alive during the transfer" do
    received = String.new
    easy = Ethon::Easy.new(:url => url)
    easy.writefunction = proc do |stream, size, num, _|
      GC.start
      received << stream.read_string(size * num)
      size * num
    end
    GC.start

    expect(easy.perform).to eq(:ok)
    expect(received).to include('"REQUEST_METHOD":"GET"')
  end

  it "keeps a custom read callback alive during an upload" do
    body = "abc"
    reads = 0
    easy = Ethon::Easy.new(:url => url, :upload => true)
    easy.infilesize = body.bytesize
    easy.readfunction = proc do |stream, _, _, _|
      GC.start
      reads += 1
      if reads == 1
        stream.write_string(body, body.bytesize)
        body.bytesize
      else
        0
      end
    end
    GC.start

    expect(easy.perform).to eq(:ok)
    expect(JSON.parse(easy.response_body)["body"]).to eq(body)
  end

  it "keeps the progress callback alive during the transfer" do
    calls = 0
    easy = Ethon::Easy.new(:url => url)
    easy.on_progress do
      GC.start
      calls += 1
    end

    expect(easy.perform).to eq(:ok)
    expect(calls).to be > 0
  end

  it "streams to a file while the body callback collects garbage" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "body")
      easy = Ethon::Easy.new(:url => url)
      easy.file = path
      easy.on_body { |_chunk| GC.start }
      GC.start

      expect(easy.perform).to eq(:ok)
      expect(easy.instance_variable_get(:@response_body_io)).to be_nil
      expect(File.read(path)).to include('"REQUEST_METHOD":"GET"')
    end
  end

  it "survives repeated duplication and collection" do
    20.times do
      easy = Ethon::Easy.new
      easy.headers = { "X-Test" => "yes" }
      easy.on_complete { }
      copy = easy.dup

      copy.cleanup
      easy.cleanup
      GC.start
    end
  end
end
