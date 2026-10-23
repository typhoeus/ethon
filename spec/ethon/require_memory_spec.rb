# frozen_string_literal: true
require 'rbconfig'

describe "require 'ethon' memory usage" do
  # Retained Ruby heap memory that requiring ethon is allowed to add.
  # This intentionally stays tight: eagerly loading large optional
  # dependencies here makes every process that loads ethon pay for them.
  # Update it deliberately when the baseline changes. The current baseline
  # after removing the eager dependency load is just under 1 MB.
  MAX_RETAINED_BYTES = 1024 * 1024

  it "retains less than 1 MB" do
    script = <<~RUBY
      require 'objspace'

      3.times { GC.start }
      before = ObjectSpace.memsize_of_all

      require 'ethon'

      3.times { GC.start }
      retained = ObjectSpace.memsize_of_all - before

      if retained > #{MAX_RETAINED_BYTES}
        warn "require 'ethon' retained \#{retained} bytes (limit #{MAX_RETAINED_BYTES})"
        exit 1
      end
    RUBY

    lib = File.expand_path('../../lib', __dir__)
    expect(system(RbConfig.ruby, '-I', lib, '-e', script)).to be(true)
  end
end
