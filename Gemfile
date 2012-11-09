source :rubygems
gemspec

gem "rake"

group :development, :test do
  gem "rspec", "~> 2.11"

  gem "sinatra", "~> 1.3"
  gem "json"

  unless ENV["CI"]
    gem "guard-rspec", "~> 0.7"
    gem 'rb-fsevent', '~> 0.9.1'
  end
end

group :perf do
  gem "patron", "~> 0.4"
  gem "curb", "~> 0.8.0"
end
