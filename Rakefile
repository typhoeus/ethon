$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/core/rake_task'
# RSpec::Core::RakeTask.new do |t|

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.ruby_opts = "-W -I./spec -rspec_helper"
end

desc "Start up the test servers"
task :start do
  require 'spec/support/boot'
  begin
    Boot.start_servers(:rake)
  rescue Exception
  end
end

task :default => :spec
