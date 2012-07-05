require "spec_helper"

describe Ethon::Loggable do

  describe "#logger=" do

    let(:logger) do
      Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
      end
    end

    before do
      Ethon.logger = logger
    end

    it "sets the logger" do
      Ethon.logger.should eq(logger)
    end
  end
end
