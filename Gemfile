source "https://rubygems.org"
gemspec

if Gem.ruby_version < Gem::Version.new("1.9.3")
  gem "rake", "< 11"
else
  gem "rake"
end

group :development, :test do
  gem "rspec", "~> 3.4"

  gem "sinatra"
  gem "json"
  gem "mime-types", "~> 1.18"

  unless ENV["CI"]
    gem "guard-rspec", "~> 0.7"
    gem "rb-fsevent", "~> 0.9.1"
  end
end

group :perf do
  gem "benchmark-ips"
  gem "patron"
  gem "curb"
end
