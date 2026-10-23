# frozen_string_literal: true
require 'rbconfig'

describe "mime-types loading" do
  it "is deferred until a file is uploaded" do
    has_mime_types = Gem::Specification.find_all_by_name("mime-types").any?
    script = <<~RUBY
      require 'ethon'

      mime_loaded = -> { $LOADED_FEATURES.any? { |file| file.include?('mime/types') } }
      abort 'mime-types loaded by require' if mime_loaded.call
      abort 'MIME::Types defined by require' if defined?(MIME::Types)

      Ethon::Easy.new
      abort 'mime-types loaded by easy creation' if mime_loaded.call
      abort 'MIME::Types defined by easy creation' if defined?(MIME::Types)

      Ethon::Easy::Form.new(nil, {}).send(:mime_type, 'a.rb')
      if #{has_mime_types}
        abort 'mime-types not loaded on upload' unless mime_loaded.call
        abort 'MIME::Types not defined on upload' unless defined?(MIME::Types)
      else
        abort 'mime-types loaded without being installed' if mime_loaded.call
      end
    RUBY

    lib = File.expand_path('../../lib', __dir__)
    expect(system(RbConfig.ruby, '-I', lib, '-e', script)).to be(true)
  end
end
