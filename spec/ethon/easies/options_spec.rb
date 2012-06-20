require 'spec_helper'

describe Ethon::Easies::Options do
  let(:easy) { Ethon::Easy.new }

  describe "options" do
    let(:options) { Ethon::Easy::AVAILABLE_OPTIONS }

    it "have read accessors" do
      options.all? { |o| easy.respond_to?(o) }.should be_true
    end

    it "have write accessors" do
      options.all? { |o| easy.respond_to?("#{o}=") }.should be_true
    end

    it "can be set" do
      options.each { |o| easy.method("#{o}=").call("fu"); easy.prepare }
    end
  end

  describe "#set_options" do
    let(:url) { "http://localhost:3001/" }

    context "when option" do
      it "sets curl option" do
        easy.url = url
        Ethon::Curl.expects(:set_option).with(:url, url, easy.handle)
        easy.set_options
      end

      context "when options contains a null byte" do
        let(:url) { "http://localhost:3001/\0" }

        it "doesn't fail" do
          easy.url = url
          easy.set_options
        end
      end
    end

    context "when no option" do
      it "sets nothing" do
        Ethon::Curl.expects(:set_option).never
        easy.set_options
      end
    end
  end
end
