require 'orthos'
require 'open-uri'
require 'patron'
require "net/http"
require 'benchmark'

Benchmark.bm do |bm|

  [100_000].each do |i|
    puts "[ #{i} Creations]"

    bm.report("String.new        ") do
      i.times { String.new }
    end

    bm.report("Easy.new          ") do
      i.times { Orthos::Easy.new }
    end
  end

  GC.start

  [1000].each do |i|
    puts "[ #{i} Requests]"

    bm.report("net/http          ") do
      uri = URI.parse("http://localhost:3001/")
      i.times { Net::HTTP.get_response(uri) }
    end

    bm.report("open-uri          ") do
      i.times { open "http://localhost:3001/" }
    end

    bm.report("patron            ") do
      sess = Patron::Session.new
      i.times do
        sess.base_url = "http://localhost:3001"
        sess.get("/")
      end
    end

    bm.report("patron reuse      ") do
      sess = Patron::Session.new
      sess.base_url = "http://localhost:3001"
      i.times do
        sess.get("/")
      end
    end

    bm.report("Easy.perform      ") do
      easy = Orthos::Easy.new
      i.times do
        easy.url = "http://localhost:3001/"
        easy.prepare
        easy.perform
      end
    end

    bm.report("Easy.perform reuse") do
      easy = Orthos::Easy.new
      easy.url = "http://localhost:3001/"
      easy.prepare
      i.times { easy.perform }
    end
  end

  GC.start

  puts "[ 4 delayed Requests ]"

  bm.report("net/http          ") do
    3.times do |i|
      uri = URI.parse("http://localhost:300#{i}/?delay=1")
      Net::HTTP.get_response(uri)
    end
  end

  bm.report("open-uri          ") do
    3.times do |i|
      open("http://localhost:300#{i}/?delay=1")
    end
  end

  bm.report("patron            ") do
    sess = Patron::Session.new
    3.times do |i|
      sess.base_url = "http://localhost:300#{i}/?delay=1"
      sess.get("/")
    end
  end

  bm.report("Easy.perform      ") do
    easy = Orthos::Easy.new
    3.times do |i|
      easy.url = "http://localhost:300#{i}/?delay=1"
      easy.prepare
      easy.perform
    end
  end

  bm.report("Multi.perform     ") do
    multi = Orthos::Multi.new
    3.times do |i|
      easy = Orthos::Easy.new
      easy.url = "http://localhost:300#{i}/?delay=1"
      easy.prepare
      multi.add(easy)
    end
    multi.perform
  end
end
