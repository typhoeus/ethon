require 'spec_helper'

describe Ethon::Multi::Options do
  let(:multi) { Ethon::Multi.new }

  describe "options" do
    let(:options) { Ethon::Multi.available_options }
    let(:bool_options) { Ethon::Multi.bool_options }
    let(:int_options) { Ethon::Multi.int_options }
    let(:unspecific_options) { options - bool_options - int_options }

    it "have read accessors" do
      expect(options.all? { |o| multi.respond_to?(o) }).to be_true
    end

    it "have write accessors" do
      expect(options.all? { |o| multi.respond_to?("#{o}=") }).to be_true
    end

    context "when option in bool_options" do
      context "when value true" do
        it "sets" do
          bool_options.each { |o| multi.method("#{o}=").call(true); multi.set_options }
        end
      end

      context "when value false" do
        it "sets" do
          bool_options.each { |o| multi.method("#{o}=").call(false); multi.set_options }
        end
      end
    end

    context "when option in int_options" do
      it "sets" do
        int_options.each { |o| multi.method("#{o}=").call(1); multi.set_options }
      end
    end

    context "when option unspecific" do
      it "sets" do
        unspecific_options.each { |o| multi.method("#{o}=").call("hello"); multi.set_options }
      end
    end
  end

  describe "#set_options" do
    let(:pipelining) { true }

    context "when option" do
      it "sets curl option" do
        multi.pipelining = pipelining
        Ethon::Curl.should_receive(:set_option).at_least(:once)
        multi.set_options
      end

      context "when options contains a null byte" do
        let(:url) { "http://localhost:3001/\0" }

        it "doesn't fail" do
          multi.pipelining = pipelining
          multi.set_options
        end
      end
    end

    context "when no option" do
      it "sets nothing" do
        Ethon::Curl.should_receive(:set_option).at_least(:once)
        multi.set_options
      end
    end
  end
end
