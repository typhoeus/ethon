require 'spec_helper'

describe Ethon::Easy::Http do
  let(:easy) { Ethon::Easy.new }

  describe "#http_request" do
    let(:url) { "http://localhost:3001/" }
    let(:action_name) { :get }
    let(:options) { {} }

    let(:get) { mock(:setup) }
    let(:get_class) { Ethon::Easy::Http::Get }

    it "instanciates action" do
      get.should_receive(:setup)
      get_class.should_receive(:new).and_return(get)
      easy.http_request(url, action_name, options)
    end
  end
end
