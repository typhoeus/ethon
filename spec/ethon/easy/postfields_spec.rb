# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy do
  describe "#postfields=" do
    let(:easy) { Ethon::Easy.new }
    let(:body) { "a=1" }

    it "retains the string libcurl references" do
      easy.postfields = body

      expect(easy.instance_variable_get(:@postfields)).to be(body)
    end

    it "clears the retained string on reset" do
      easy.postfields = body

      easy.reset

      expect(easy.instance_variable_get(:@postfields)).to be_nil
    end
  end
end
