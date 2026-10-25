# frozen_string_literal: true
require 'spec_helper'

describe "option error messages" do
  let(:option) { "bad\nX-Injected: yes" }

  [Ethon::Errors::InvalidOption, Ethon::Errors::UnsupportedOption].each do |error_class|
    it "escapes control characters in #{error_class}" do
      message = error_class.new(option).message

      expect(message).to include('bad\nX-Injected: yes')
      expect(message).not_to include("\n")
    end
  end

  it "escapes control characters in SetOption" do
    message = Ethon::Errors::SetOption.new(option, :out_of_memory).message

    expect(message).to include('bad\nX-Injected: yes')
    expect(message).not_to include("\n")
  end

  it "escapes NUL bytes in option names" do
    message = Ethon::Errors::InvalidOption.new("bad\0name").message

    expect(message).to include("bad")
    expect(message).not_to include("\0")
  end

  it "keeps ordinary option names readable" do
    expect(Ethon::Errors::InvalidOption.new(:url).message).
      to eq("The option: :url is invalid.")

    expect(Ethon::Errors::UnsupportedOption.new(:tcp_keepcnt).message).
      to match(/does not support the option: :tcp_keepcnt/)
  end

  it "does not let an Easy option key inject a log line" do
    easy = Ethon::Easy.new

    expect { easy.set_attributes(option => 1) }.
      to raise_error(Ethon::Errors::InvalidOption) { |error|
        expect(error.message).not_to include("\n")
      }
  ensure
    easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
  end
end
