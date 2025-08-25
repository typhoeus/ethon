# frozen_string_literal: true
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'bundler'
Bundler.setup
require "ethon"
require 'rspec'

# Ethon.logger = Logger.new($stdout).tap do |log|
#   log.level = Logger::DEBUG
# end
