# frozen_string_literal: true
require 'rbconfig'

describe "mime-types loading" do
  def run_ethon(script)
    lib = File.expand_path('../../lib', __dir__)
    system(RbConfig.ruby, '-I', lib, '-e', script)
  end

  it "does not load mime-types when ethon is required" do
    script = <<~RUBY
      require 'ethon'
      abort 'mime-types feature loaded by require' if $LOADED_FEATURES.any? { |file| file.include?('mime/types') }
      abort 'MIME::Types loaded by require' if defined?(MIME::Types)
    RUBY

    expect(run_ethon(script)).to be(true)
  end

  it "does not load mime-types when an easy handle is created" do
    script = <<~RUBY
      require 'ethon'
      Ethon::Easy.new
      abort 'mime-types feature loaded by easy creation' if $LOADED_FEATURES.any? { |file| file.include?('mime/types') }
      abort 'MIME::Types loaded by easy creation' if defined?(MIME::Types)
    RUBY

    expect(run_ethon(script)).to be(true)
  end

  it "loads mime-types on the first upload" do
    skip "mime-types is not installed" unless Gem::Specification.find_all_by_name("mime-types").any?

    script = <<~RUBY
      require 'ethon'
      Ethon::Easy::Form.new(nil, {}).send(:mime_type, 'a.rb')
      abort 'mime-types not loaded on upload' unless $LOADED_FEATURES.any? { |file| file.include?('mime/types') }
      abort 'MIME::Types not defined on upload' unless defined?(MIME::Types)
    RUBY

    expect(run_ethon(script)).to be(true)
  end
end
