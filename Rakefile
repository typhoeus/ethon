$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/core/rake_task'
# RSpec::Core::RakeTask.new do |t|

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.ruby_opts = "-W -I./spec -rspec_helper"
end

task :default => :spec
