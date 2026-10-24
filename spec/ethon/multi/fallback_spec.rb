# frozen_string_literal: true
require 'spec_helper'

describe "Ethon::Multi wait strategies" do
  let(:multi) { Ethon::Multi.new }
  let(:easy) { Ethon::Easy.new }

  after do
    multi.easy_handles.dup.each { |handle| multi.delete(handle) }
  end

  it "performs with curl_multi_wait when poll is unavailable" do
    allow(Ethon::Curl).to receive(:respond_to?).and_call_original
    allow(Ethon::Curl).to receive(:respond_to?).with(:multi_poll).and_return(false)
    multi.init_vars
    easy.url = "http://127.0.0.1:3001/?delay=0.1"
    multi.add(easy)

    expect(multi.instance_variable_get(:@wait_strategy)).to eq(:wait)
    expect(multi).to receive(:wait).at_least(:once).and_call_original

    multi.perform
    expect(easy.return_code).to eq(:ok)
  end

  it "performs with select when poll and wait are unavailable" do
    allow(Ethon::Curl).to receive(:respond_to?).and_call_original
    allow(Ethon::Curl).to receive(:respond_to?).with(:multi_poll).and_return(false)
    allow(Ethon::Curl).to receive(:respond_to?).with(:multi_wait).and_return(false)
    multi.init_vars
    easy.url = "http://127.0.0.1:3001/?delay=0.1"
    multi.add(easy)

    expect(multi.instance_variable_get(:@wait_strategy)).to eq(:select)
    expect(multi).to receive(:set_fds).at_least(:once).and_call_original

    multi.perform
    expect(easy.return_code).to eq(:ok)
  end
end
