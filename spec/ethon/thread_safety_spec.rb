# frozen_string_literal: true
require 'spec_helper'

describe "thread safety" do
  it "creates and performs separate easy handles concurrently" do
    results = 5.times.map do
      Thread.new do
        easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
        easy.perform
        easy.return_code
      end
    end.map(&:value)

    expect(results).to all(eq(:ok))
  end

  it "creates and performs separate multi handles concurrently" do
    results = 5.times.map do
      Thread.new do
        multi = Ethon::Multi.new
        easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
        multi.add(easy)
        multi.perform
        easy.return_code
      end
    end.map(&:value)

    expect(results).to all(eq(:ok))
  end
end
