# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::FormOption do
  {
    :end => 17,
    :obsolete2 => 18,
    :stream => 19,
    :contentlen => 20,
    :last => 21
  }.each do |name, value|
    it "maps #{name} to #{value}" do
      expect(described_class[name]).to eq(value)
    end
  end
end
