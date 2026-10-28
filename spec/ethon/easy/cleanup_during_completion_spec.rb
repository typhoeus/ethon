# frozen_string_literal: true
require 'spec_helper'
require 'tmpdir'

describe "Ethon::Easy cleanup from on_complete" do
  let(:url) { "http://localhost:3001/" }

  it "allows cleanup for a Multi transfer" do
    multi = Ethon::Multi.new
    easy = Ethon::Easy.new(:url => url)
    easy.on_complete { |e| e.cleanup }
    multi.add(easy)

    expect { multi.perform }.not_to raise_error
    expect(multi.easy_handles).to be_empty
    expect { easy.url = url }.
      to raise_error(Ethon::Errors::EthonError, /cleaned up/)
  ensure
    multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
  end

  it "keeps a streamed response file after the transfer" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "body")
      easy = Ethon::Easy.new(:url => url, :file => path)
      easy.on_complete { |e| e.cleanup }

      expect { easy.perform }.not_to raise_error
      expect(File.binread(path)).to include('"REQUEST_METHOD":"GET"')
    end
  end

  it "still raises callback errors when the completion callback cleans up" do
    easy = Ethon::Easy.new(:url => url)
    easy.on_body { raise "body callback failed" }
    easy.on_complete { |e| e.cleanup }

    expect { easy.perform }.to raise_error("body callback failed")
  end
end
