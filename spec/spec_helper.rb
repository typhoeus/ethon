$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "orthos"
require "mocha"
require "json"
require "rspec"


RSpec.configure do |config|
  config.mock_with(:mocha)
end
