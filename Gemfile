source :rubygems
gemspec

gem "rake"

group :development, :test do
  gem "rspec", "~> 2.11"

  gem "sinatra", "~> 1.3"

  if RUBY_PLATFORM == "java"
    gem "spoon"
  else
    gem "patron", "~> 0.4"
    gem "curb", "~> 0.8.0"
  end

  unless ENV["CI"]
    gem "guard-rspec", "~> 0.7"
  end
end
