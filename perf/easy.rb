require 'orthos'
require 'open-uri'
require "net/http"
require 'benchmark'

Benchmark.bm do |bm|

  [100_000].each do |i|
    puts "[ #{i} ]"

    bm.report("Easy.new    ") do
      i.times { Orthos::Easy.new }
    end

    bm.report("String.new  ") do
      i.times { String.new }
    end
  end

  GC.start

  [1000].each do |i|
    puts "[ #{i} ]"

    bm.report("Easy.perform") do
      easy = Orthos::Easy.new
      easy.url = "http://localhost:3001/"
      easy.prepare
      i.times { easy.perform }
    end

    bm.report("open        ") do
      i.times { open "http://localhost:3001/" }
    end

    bm.report("net/http    ") do
      uri = URI.parse("http://localhost:3001/")
      i.times { Net::HTTP.get_response(uri) }
    end
  end
end
