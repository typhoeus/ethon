# frozen_string_literal: true
require 'spec_helper'

describe "connection reuse" do
  let(:easy) { Ethon::Easy.new(:url => "http://localhost:3001/") }

  after { easy.cleanup }

  it "reuses the connection for the next request" do
    easy.perform
    first = easy.conn_id

    easy.perform

    expect(easy.conn_id).to eq(first)
  end

  it "opens a new connection with fresh_connect" do
    easy.perform
    first = easy.conn_id

    easy.fresh_connect = true
    easy.perform

    expect(easy.conn_id).not_to eq(first)
  end
end
