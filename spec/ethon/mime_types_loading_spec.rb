# frozen_string_literal: true
require 'rbconfig'

describe "mime-types loading" do
  it "is deferred until a file is uploaded" do
    script = <<~RUBY
      require 'ethon'
      abort 'mime-types loaded by require' if defined?(MIME::Types)
      Ethon::Easy::Form.new(nil, {}).send(:mime_type, 'a.rb')
      abort 'mime-types not loaded on upload' unless defined?(MIME::Types)
    RUBY
    lib = File.expand_path('../../lib', __dir__)
    expect(system(RbConfig.ruby, '-I', lib, '-e', script)).to be(true)
  end
end
