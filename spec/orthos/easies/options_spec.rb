require 'spec_helper'

describe Orthos::Easies::Options do
  let(:easy) { Orthos::Easy.new }

  describe "options" do
    let(:options) { Orthos::Easy::AVAILABLE_OPTIONS }

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
        Orthos::Curl.expects(:set_option).with(:url, url, easy.handle)
        easy.set_options
      end
    end

    context "when no option" do
      it "sets nothing" do
        Orthos::Curl.expects(:set_option).never
        easy.set_options
      end
    end
  end
end
