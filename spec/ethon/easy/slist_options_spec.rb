# frozen_string_literal: true
require 'spec_helper'

describe "curl_slist options" do
  let(:easy) { Ethon::Easy.new }
  let(:lines) { ["localhost:3001:127.0.0.1"] }
  let(:slist) { Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(lines)) }

  it "retains an slist assigned to an option" do
    easy.resolve = slist

    expect(easy.instance_variable_get(:@slists)[:resolve]).to be(slist)
  end

  it "retains slists for every slist option" do
    easy.resolve = slist
    easy.connect_to = slist

    expect(easy.instance_variable_get(:@slists)).to include(
      :resolve => slist,
      :connect_to => slist
    )
  end

  it "releases an slist when the option is cleared" do
    easy.resolve = slist

    easy.resolve = nil

    expect(easy.instance_variable_get(:@slists)).not_to have_key(:resolve)
  end

  it "shares retained slists with a duplicate" do
    easy.resolve = slist

    copy = easy.dup

    expect(copy.instance_variable_get(:@slists)).to eq(:resolve => slist)
  end

  it "keeps duplicate changes independent" do
    other = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["example.com:80:127.0.0.1"]))
    easy.resolve = slist
    copy = easy.dup

    copy.resolve = other

    expect(easy.instance_variable_get(:@slists)).to eq(:resolve => slist)
    expect(copy.instance_variable_get(:@slists)).to eq(:resolve => other)
  end

  it "clears retained slists on reset" do
    easy.resolve = slist

    easy.reset

    expect(easy.instance_variable_get(:@slists)).to be_nil
  end

  it "releases retained slists on cleanup" do
    easy.resolve = slist

    easy.cleanup

    expect(easy.instance_variable_get(:@slists)).to be_nil
  end

  it "does not retain request header lists twice" do
    easy.headers = { "X-Test" => "yes" }

    expect(easy.instance_variable_get(:@slists)).to be_nil
    expect(easy.header_list).to be_a(Ethon::Curl::Slist)
  end

  it "uses a retained resolve list" do
    easy.url = "http://localhost:3001/"
    easy.resolve = slist

    expect(easy.perform).to eq(:ok)
    expect(easy.response_code).to eq(200)
  end
end
