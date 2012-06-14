require 'spec_helper'

describe Ethon::Easies::Http do
  let(:easy) { Ethon::Easy.new }

  describe "#http_request" do
    let(:url) { "http://localhost:3001/" }
    let(:action_name) { :get }
    let(:options) { {} }

    let(:get) { mock(:setup) }
    let(:get_class) { Ethon::Easies::Http::Actions::Get }

    it "fabricates action" do
      Ethon::Easies::Http::Action.expects(:fabricate).with(action_name).returns(get_class)
      easy.http_request(url, action_name, options)
    end

    it "instanciates action" do
      Ethon::Easies::Http::Action.expects(:fabricate).with(action_name).returns(get_class)
      get_class.expects(:new).returns(get)
      easy.http_request(url, action_name, options)
    end
  end
end
