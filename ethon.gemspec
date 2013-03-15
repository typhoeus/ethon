# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'ethon/version'

Gem::Specification.new do |s|
  s.name         = "ethon"
  s.version      = Ethon::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Hans Hasselberg"]
  s.email        = ["me@hans.io"]
  s.homepage     = "https://github.com/typhoeus/ethon"
  s.summary      = "Libcurl wrapper."
  s.description  = "Very lightweight libcurl wrapper."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = '[none]'

  s.add_dependency('ffi', ['>= 1.3.0'])
  s.add_dependency('mime-types', ['~> 1.18'])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md Gemfile LICENSE README.md Rakefile)
  s.require_path = 'lib'
end
