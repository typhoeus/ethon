# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'orthos/version'

Gem::Specification.new do |s|
  s.name         = "orthos"
  s.version      = Orthos::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Hans Hasselberg"]
  s.email        = "me@hans.io"
  s.homepage     = "https://github.com/typhoeus/orthos"
  s.summary      = "Libcurl wrapper."
  s.description  = %q{Fu}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = '[none]'

  s.add_dependency('ffi', ['~> 1.0'])

  s.add_development_dependency('sinatra', ['~> 1.3'])
  s.add_development_dependency('json', ['~> 1.7'])
  s.add_development_dependency('rake', ['~> 0.9'])
  s.add_development_dependency("mocha", ["~> 0.10"])
  s.add_development_dependency("rspec", ["~> 2.10"])
  s.add_development_dependency("guard-rspec", ["~> 0.6"])
  s.add_development_dependency('spoon') if RUBY_PLATFORM == "java"

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md Gemfile LICENSE README.md Rakefile)
  s.require_path = lib
end
