source "https://rubygems.org"
gemspec

gem "rake"

group :development, :test do
  gem "rspec", "~> 2.11"

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
