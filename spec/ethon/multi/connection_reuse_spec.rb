# frozen_string_literal: true
require 'spec_helper'

describe "Multi connection reuse" do
  let(:multi) { Ethon::Multi.new }

  after { multi.cleanup }

  def request_batch(count)
    easies = Array.new(count) do
      # The delay makes the requests overlap so libcurl opens one connection
      # per easy instead of serializing them over a single connection.
      Ethon::Easy.new(:url => "http://localhost:3001/?delay=0.05")
    end
    easies.each { |easy| multi.add(easy) }

    multi.perform

    ids = easies.map(&:conn_id)
    easies.each(&:cleanup)
    ids
  end

  it "reuses pooled connections for a later batch" do
    first = request_batch(8)
    skip "CURLINFO_CONN_ID is unavailable in this libcurl" if first.any?(&:nil?)

    second = request_batch(8)

    expect(first.uniq.length).to eq(8)
    expect(second.sort).to eq(first.sort)
  end
end
