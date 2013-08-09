require 'spec_helper'

describe Ethon::Easy::Http do
  let(:easy) { Ethon::Easy.new }

  describe "#http_request" do
    let(:url) { "http://localhost:3001/" }
    let(:action_name) { :get }
    let(:options) { {} }

    let(:get) { double(:setup) }
    let(:get_class) { Ethon::Easy::Http::Get }

    it "instanciates action" do
      get.should_receive(:setup)
      get_class.should_receive(:new).and_return(get)
      easy.http_request(url, action_name, options)
    end

    context "when requesting" do
      [ :get, :post, :put, :delete, :head, :patch, :options ].map do |action|
        it "returns ok" do
          easy.http_request(url, action, options)
          easy.perform
          expect(easy.return_code).to be(:ok)
        end

        unless action == :head
          it "makes a #{action.to_s.upcase} request" do
            easy.http_request(url, action, options)
            easy.perform
            expect(easy.response_body).to include("\"REQUEST_METHOD\":\"#{action.to_s.upcase}\"")
          end
        end
      end

      it "makes requests with custom HTTP verbs" do
        easy.http_request(url, :purge, options)
        easy.perform
        expect(easy.response_body).to include(%{"REQUEST_METHOD":"PURGE"})
      end
    end
  end
end
