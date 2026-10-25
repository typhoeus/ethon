# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Errors::InvalidValue do
  let(:value) { "http://example.com/\r\nX-Injected: yes" }
  let(:error) { described_class.new(:url, value) }

  it "escapes control characters in the value" do
    expect(error.message).to include('http://example.com/\r\nX-Injected: yes')
    expect(error.message).not_to include("\r")
    expect(error.message).not_to include("\n")
  end

  it "names the option" do
    expect(error.message).to include("url")
  end
end
