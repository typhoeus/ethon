# frozen_string_literal: true
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'bundler'
Bundler.setup

def trace?
  ENV['TRACE'] == 'true'
end

require 'appmap/rspec'

if trace?
  stack = {}
  $tp = TracePoint.trace(:call, :return) do |tp|
    stack[Thread.current] ||= []
    (0..stack[Thread.current].length).each { $stdout.write '  '}
    $stdout.write [tp.path, tp.lineno, tp.event].join(' ')
    $stdout.puts
    if tp.event == :call
      stack[Thread.current] << tp.event
    else
      stack[Thread.current].pop
    end
  end
  $tp.enable
end

require "ethon"

if $tp
  $tp.disable
end

require 'rspec'

if defined? require_relative
  require_relative 'support/localhost_server'
  require_relative 'support/server'
else
  require 'support/localhost_server'
  require 'support/server'
end

# Ethon.logger = Logger.new($stdout).tap do |log|
#   log.level = Logger::DEBUG
# end

RSpec.configure do |config|
  # config.order = :rand

  config.before(:suite) do
    LocalhostServer.new(TESTSERVER.new, 3001)
  end
end
