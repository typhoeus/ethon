require 'spec_helper'

describe Ethon::Easies::Http do
  let(:easy) { Ethon::Easy.new }

  describe "#http_request" do
    let(:url) { "http://localhost:3001/" }
    let(:action_name) { :get }
    let(:options) { {} }

    let(:get) { mock(:setup) }
    let(:get_class) { Ethon::Easies::Http::Get }

    it "instanciates action" do
      get_class.expects(:new).returns(get)
      easy.http_request(url, action_name, options)
    end
  end
end
