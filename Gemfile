# frozen_string_literal: true
source "https://rubygems.org"
gemspec

gem "rake"

group :development, :test do
  gem "rspec", "~> 3.4"
  
  if Gem.ruby_version < Gem::Version.new("3.0.0")
    gem "sinatra", "~> 2.2"
  else
    gem "sinatra"
  end
  
  gem "rackup"
  gem "json"
  gem "mime-types", "~> 1.18"
  gem "mustermann"
  gem "webrick"
end

group :perf do
  gem "benchmark-ips"
  gem "patron"
  gem "curb"
end
