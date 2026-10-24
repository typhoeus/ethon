# frozen_string_literal: true
require "spec_helper"

describe Ethon::Loggable do

  describe "#logger=" do
    around do |example|
      original = Ethon.logger
      example.run
    ensure
      Ethon.logger = original
    end

    let(:logger) do
      Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
      end
    end

    before do
      Ethon.logger = logger
    end

    it "sets the logger" do
      expect(Ethon.logger).to eq(logger)
    end

    it "falls back to a default logger when set to nil" do
      Ethon.logger = nil

      expect(Ethon.logger).to be_a(Logger)
    end
  end
end
