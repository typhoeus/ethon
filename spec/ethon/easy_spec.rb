require 'spec_helper'

describe Ethon::Easy do
  let(:easy) { Ethon::Easy.new }

  describe ".new" do
    it "inits curl" do
      Ethon::Curl.should_receive(:init)
      easy
    end

    context "when options are empty" do
      it "sets only callbacks" do
        Ethon::Easy.any_instance.should_receive(:set_callbacks)
        Ethon::Curl.should_receive(:set_option).never
        easy
      end
    end

    context "when options not empty" do
      context "when verbose is set" do
        let(:options) { { :verbose => true } }
        let(:easy) { Ethon::Easy.new(options) }

        it "sets verbose" do
          Ethon::Easy.any_instance.should_receive(:set_callbacks)
          Ethon::Curl.should_receive(:set_option).with do |option, value, _|
            expect(option).to be(:verbose)
            expect(value).to be(true)
          end
          easy
        end
      end
    end
  end

  describe "#set_attributes" do
    context "when options are empty" do
      it "sets nothing" do
        Ethon::Easy.any_instance.should_receive(:set_callbacks)
        Ethon::Curl.should_receive(:set_option).never
        easy
      end
    end

    context "when options aren't empty" do
      context "when valid key" do
        it "sets" do
          easy.should_receive(:verbose=).with(true)
          easy.set_attributes({:verbose => true})
        end
      end

      context "when invalid key" do
        it "raises invalid option error" do
          expect{ easy.set_attributes({:fubar => 1}) }.to raise_error(Ethon::Errors::InvalidOption)
        end
      end
    end
  end

  describe "#reset" do
    before { easy.url = "www.example.com" }

    it "resets url" do
      easy.reset
      expect(easy.url).to be_nil
    end

    it "resets hash" do
      easy.reset
      expect(easy.instance_variable_get(:@hash)).to be_nil
    end

    it "resets easy handle" do
      Ethon::Curl.should_receive(:easy_reset)
      easy.reset
    end

    it "resets on_complete" do
      easy.on_complete { p 1 }
      easy.reset
      expect(easy.on_complete).to be_empty
    end
  end

  describe "#to_hash" do
    [
      :return_code, :response_code, :response_headers, :response_body,
      :total_time, :starttransfer_time, :appconnect_time,
      :pretransfer_time, :connect_time, :namelookup_time,
      :effective_url, :primary_ip, :redirect_count
    ].each do |name|
      it "contains #{name}" do
        expect(easy.to_hash).to include(name)
      end
    end
  end

  describe "#log_inspect" do
    [ :url, :response_code, :return_code, :total_time ].each do |name|
      it "contains #{name}" do
        expect(easy.log_inspect).to match name.to_s
      end
    end
  end
end
