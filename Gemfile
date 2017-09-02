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

  if Gem.ruby_version < Gem::Version.new("2.0.0")
    gem "json", "< 2"
  else
    gem "json"
  end

  gem "mime-types", "~> 1.18"

  if Gem.ruby_version >= Gem::Version.new("2.2.0")
    gem "mustermann"
  elsif Gem.ruby_version >= Gem::Version.new("2.1.0")
    gem "mustermann", "0.4.0"
  elsif Gem.ruby_version >= Gem::Version.new("2.0.0")
    gem "mustermann", "0.3.1"
  else
    gem "mustermann", "0.2.0"
  end
end

group :perf do
  gem "benchmark-ips"
  gem "patron"
  gem "curb"
end
