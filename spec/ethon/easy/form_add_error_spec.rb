# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Form do
  it "raises when curl_formadd fails" do
    skip "curl_formadd is unavailable" unless Ethon::Curl.respond_to?(:formadd)

    form = described_class.new(Ethon::Easy.new, { :a => "b" })
    allow(Ethon::Curl).to receive(:formadd).and_return(1)

    expect { form.materialize }.to raise_error(Ethon::Errors::FormAdd, /1/)
  end
end
