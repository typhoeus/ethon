$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "ethon"
require "mocha"
require "json"
require "rspec"
require_relative 'support/boot.rb'

RSpec.configure do |config|
  config.mock_with(:mocha)

  config.before(:suite) do
    Boot.start_servers
  end
end
