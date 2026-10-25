# frozen_string_literal: true
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'bundler'
Bundler.setup
require "ethon"
require 'rspec'

require_relative 'support/localhost_server'
require_relative 'support/server'

# Ethon.logger = Logger.new($stdout).tap do |log|
#   log.level = Logger::DEBUG
# end

RSpec.configure do |config|
  config.order = :random

  config.before(:suite) do
    # Initialize libcurl before any example can install a logger expectation;
    # otherwise the one-time init debug message depends on example order.
    Ethon::Curl.init
    LocalhostServer.new(TESTSERVER.new, 3001)
  end
end
