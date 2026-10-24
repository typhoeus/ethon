# frozen_string_literal: true
require 'spec_helper'

describe "thread safety" do
  it "creates and performs separate easy handles concurrently" do
    results = 5.times.map do
      Thread.new do
        easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
        easy.perform
        easy.return_code
      end
    end.map(&:value)

    expect(results).to all(eq(:ok))
  end

  it "creates and performs separate multi handles concurrently" do
    results = 5.times.map do
      Thread.new do
        multi = Ethon::Multi.new
        easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
        multi.add(easy)
        multi.perform
        easy.return_code
      end
    end.map(&:value)

    expect(results).to all(eq(:ok))
  end

  it "duplicates, performs, and cleans up handles concurrently" do
    results = 4.times.map do
      Thread.new do
        5.times do
          easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
          easy.on_body { |_chunk| }
          copy = easy.dup
          copy.perform
          easy.cleanup
          copy.cleanup
          GC.start
        end
        :ok
      end
    end.map(&:value)

    expect(results).to all(eq(:ok))
  end

  it "reads the option table concurrently" do
    sizes = 4.times.map do
      Thread.new { 20.times.map { Ethon::Curl.easy_option_list.size } }
    end.flat_map(&:value)

    expect(sizes.uniq.size).to eq(1)
  end

  it "shares cookies across threads with locking callbacks" do
    mutex = Mutex.new
    share = Ethon::Curl::Share.new
    share.lockfunction = proc { |*| mutex.lock }
    share.unlockfunction = proc { |*| mutex.unlock }
    share.share(:cookie)

    easies = Array.new(4) do |i|
      easy = Ethon::Easy.new
      easy.cookiefile = ""
      easy.share = share
      easy.cookielist = "example.com\tFALSE\t/\tFALSE\t0\tname#{i}\tvalue"
      easy
    end

    threads = easies.each_with_index.map do |easy, i|
      Thread.new do
        10.times do
          cookies = easy.cookielist
          raise "missing cookie #{i}" unless cookies.any? { |line| line.include?("name#{i}") }
        end
        :ok
      end
    end

    expect(threads.map(&:value)).to all(eq(:ok))
  end
end
