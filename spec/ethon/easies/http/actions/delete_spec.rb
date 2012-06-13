require 'spec_helper'

describe Ethon::Easies::Http::Actions::Delete do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:delete) { described_class.new(url, {:params => params, :body => form}) }

  it "inherits from Post" do
    described_class.should < Ethon::Easies::Http::Actions::Post
  end

  context "when requesting" do
    before do
      delete.setup(easy)
      easy.prepare
      easy.perform
    end

    it "makes a delete request" do
      easy.response_body.should include('"REQUEST_METHOD":"DELETE"')
    end
  end
end
