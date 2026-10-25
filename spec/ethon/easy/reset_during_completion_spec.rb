# frozen_string_literal: true
require 'spec_helper'
require 'tmpdir'

describe "resetting an Easy from on_complete" do
  let(:url) { "http://localhost:3001/" }

  it "allows the release pattern used by Typhoeus" do
    easy = Ethon::Easy.new(:url => url, :errorbuffer => true)

    easy.on_complete do |easy|
      easy.cookielist = "flush"
      easy.cookielist = "all"
      easy.reset
    end

    expect { easy.perform }.not_to raise_error
    expect(easy.url).to be_nil
  end

  it "leaves the Easy usable for the next request" do
    easy = Ethon::Easy.new(:url => url)
    easy.on_complete { |e| e.reset }

    expect { easy.perform }.not_to raise_error

    # reset clears the completion callbacks too, so this request is not reset.
    easy.url = "#{url}second"

    expect { easy.perform }.not_to raise_error
    expect(easy.response_code).to eq(200)
    expect(easy.response_body).to include('"PATH_INFO":"/second"')
  end

  it "closes a streamed response file before the completion callbacks finish" do
    path = File.join(Dir.tmpdir, "ethon-reset-on-complete-#{Process.pid}")
    easy = Ethon::Easy.new(:url => "#{url}binary/16", :file => path)
    easy.on_complete { |e| e.reset }

    expect { easy.perform }.not_to raise_error
    expect(File.binread(path).bytesize).to eq(16)
  ensure
    File.unlink(path) if path && File.exist?(path)
  end

  it "allows resetting an Easy driven by a Multi" do
    multi = Ethon::Multi.new
    easy = Ethon::Easy.new(:url => url)
    easy.on_complete { |e| e.reset }
    multi.add(easy)

    expect { multi.perform }.not_to raise_error
    expect(multi.easy_handles).to be_empty
    expect(easy.url).to be_nil
  ensure
    multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
  end

  it "still raises callback errors when the completion callback resets" do
    easy = Ethon::Easy.new(:url => url)
    easy.on_body { raise "body callback failed" }
    easy.on_complete { |e| e.reset }

    expect { easy.perform }.to raise_error("body callback failed")
  end

  it "still raises callback errors for a Multi transfer when the completion callback resets" do
    multi = Ethon::Multi.new
    easy = Ethon::Easy.new(:url => url)
    easy.on_body { raise "body callback failed" }
    easy.on_complete { |e| e.reset }
    multi.add(easy)

    expect { multi.perform }.to raise_error("body callback failed")
    expect(multi.easy_handles).to be_empty
  ensure
    multi.cleanup if multi && !multi.instance_variable_get(:@cleaned_up)
  end

  it "refuses to reset from a body callback" do
    easy = Ethon::Easy.new(:url => url)
    easy.on_body { easy.reset }

    expect { easy.perform }.
      to raise_error(Ethon::Errors::EthonError, /performing/)
  end
end
