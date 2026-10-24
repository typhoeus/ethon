# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe "Ethon::Multi response routing" do
  let(:multi) { Ethon::Multi.new }

  after do
    multi.easy_handles.dup.each { |easy| multi.delete(easy) }
  end

  it "delivers every response to the handle that requested it" do
    easies = 6.times.map do |i|
      easy = Ethon::Easy.new
      easy.http_request(
        "http://127.0.0.1:3001/request-#{i}",
        :get,
        :params => { :id => i }
      )
      easy
    end
    easies.each { |easy| multi.add(easy) }

    multi.perform

    easies.each_with_index do |easy, i|
      body = JSON.parse(easy.response_body)
      expect(body["PATH_INFO"]).to eq("/request-#{i}")
      expect(body["QUERY_STRING"]).to eq("id=#{i}")
    end
  end
end
