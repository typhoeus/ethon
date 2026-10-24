# frozen_string_literal: true
require 'spec_helper'
require 'rbconfig'

describe "repeated Easy and Multi transfers" do
  it "does not accumulate native handles or Easy objects" do
    script = <<~RUBY
      require "ethon"
      require "tmpdir"
      require "fileutils"

      url = "http://127.0.0.1:3001/"
      iterations = 20

      def snapshot
        GC.start
        GC.start
        [
          Ethon::Curl::OwnedPointer.owners.size,
          ObjectSpace.each_object(Ethon::Easy).count,
          ObjectSpace.each_object(File).count
        ]
      end

      def duplicate_requests(n, url)
        n.times do
          easy = Ethon::Easy.new(:url => url)
          easy.on_body { |_chunk| }
          copy = easy.dup
          copy.perform
          easy.cleanup
        end
      end

      def streamed_requests(n, url, path)
        n.times do
          easy = Ethon::Easy.new(:url => url)
          easy.file = path
          easy.perform
        end
      end

      def multi_requests(n, url, path)
        n.times do
          multi = Ethon::Multi.new
          easy = Ethon::Easy.new(:url => url)
          easy.file = path
          multi.add(easy)
          multi.perform
          multi.cleanup
        end
      end

      dir = Dir.mktmpdir
      begin
        path = File.join(dir, "body")
        duplicate_requests(5, url)
        streamed_requests(5, url, path)
        multi_requests(5, url, path)
        baseline = snapshot

        duplicate_requests(iterations, url)
        streamed_requests(iterations, url, path)
        multi_requests(iterations, url, path)
        after = snapshot

        if after[0] > baseline[0] + 2
          abort "native handle leak: \#{baseline[0]} -> \#{after[0]}"
        end
        if after[1] > baseline[1] + 2
          abort "Easy object leak: \#{baseline[1]} -> \#{after[1]}"
        end
        if after[2] > baseline[2] + 2
          abort "file descriptor leak: \#{baseline[2]} -> \#{after[2]}"
        end
      ensure
        FileUtils.remove_entry(dir)
      end
    RUBY

    lib = File.expand_path('../../lib', __dir__)
    expect(system(RbConfig.ruby, '-I', lib, '-e', script)).to be(true)
  end
end
