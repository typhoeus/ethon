$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

if RUBY_VERSION =~ /1.9/ && RUBY_ENGINE == 'ruby'
  require 'simplecov'

  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'bundler'
Bundler.setup
require "ethon"
require 'rspec'

if defined? require_relative
  require_relative 'support/boot.rb'
else
  require 'support/boot.rb'
end

# Ethon.logger = Logger.new($stdout).tap do |log|
#   log.level = Logger::DEBUG
# end

RSpec.configure do |config|
  config.order = :rand
  config.mock_with(:mocha)

  config.before(:suite) do
    Boot.start_servers
  end
end
