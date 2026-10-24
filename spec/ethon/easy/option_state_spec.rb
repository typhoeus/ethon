# frozen_string_literal: true
require 'spec_helper'

describe "Easy option state" do
  let(:easy) { Ethon::Easy.new }

  before do
    easy.url = "http://localhost:3001/original"
    easy.postfields = "original"
  end

  it "keeps the previous URL when libcurl rejects the new one" do
    allow(Ethon::Curl).to receive(:set_option).and_call_original
    allow(Ethon::Curl).to receive(:set_option).
      with(:url, "invalid", anything).
      and_raise(Ethon::Errors::InvalidValue.new(:url, "invalid"))

    expect { easy.url = "invalid" }.
      to raise_error(Ethon::Errors::InvalidValue)
    expect(easy.url).to eq("http://localhost:3001/original")
  end

  it "does not retain postfields that libcurl rejected" do
    allow(Ethon::Curl).to receive(:set_option).and_call_original
    allow(Ethon::Curl).to receive(:set_option).
      with(:postfields, "invalid", anything).
      and_raise(Ethon::Errors::InvalidValue.new(:postfields, "invalid"))

    expect { easy.postfields = "invalid" }.
      to raise_error(Ethon::Errors::InvalidValue)
    expect(easy.instance_variable_get(:@postfields)).to eq("original")
  end

  it "retains the string libcurl receives for non-string values" do
    easy.postfields = :payload

    expect(easy.instance_variable_get(:@postfields)).to eq("payload")
    expect(easy.instance_variable_get(:@postfields)).to be_a(String)
  end

  it "sends non-string postfields after garbage collection" do
    easy.url = "http://localhost:3001/echo"
    easy.postfields = :payload
    easy.postfieldsize = "payload".bytesize
    GC.start

    expect(easy.perform).to eq(:ok)
    expect(easy.response_body).to eq("payload")
  end
end
