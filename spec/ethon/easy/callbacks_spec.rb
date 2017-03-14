require 'spec_helper'

describe Ethon::Easy::Callbacks do
  let!(:easy) { Ethon::Easy.new }

  describe "#set_callbacks" do
    context "when on_progress not set" do
      before do
        expect(Ethon::Curl).to receive(:set_option).exactly(3).times
      end

      it "sets write-, debug- and headerfunction" do
        easy.set_callbacks
      end
    end

    context "when on_progress set" do
      before do
        expect(Ethon::Curl).to receive(:set_option).exactly(4).times
      end

      it "sets write-, debug-, header- and xferinfofunction" do
        easy.on_progress << proc {}
        easy.set_callbacks
      end
    end

    it "resets @response_body" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@response_body)).to eq("")
    end

    it "resets @response_headers" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@response_headers)).to eq("")
    end

    it "resets @debug_info" do
      easy.set_callbacks
      expect(easy.instance_variable_get(:@debug_info).to_a).to eq([])
    end
  end

  describe "#progress_callback" do
    it "returns 0" do
      expect(easy.progress_callback.call()).to be(0)
    end
  end

  describe "#body_write_callback" do
    let(:body_write_callback) { easy.instance_variable_get(:@body_write_callback) }
    let(:stream) { double(:read_string => "") }
    context "when body returns not :abort" do
      it "returns number bigger than 0" do
        expect(body_write_callback.call(stream, 1, 1, nil) > 0).to be(true)
      end
    end

    context "when body returns :abort" do
      before do
        easy.on_body.clear
        easy.on_body { :abort }
      end
      let(:body_write_callback) { easy.instance_variable_get(:@body_write_callback) }

      it "returns -1 to indicate abort to libcurl" do
        expect(body_write_callback.call(stream, 1, 1, nil)).to eq(-1)
      end
    end
  end
end
