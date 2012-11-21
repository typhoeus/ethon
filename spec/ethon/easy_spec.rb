require 'spec_helper'

describe Ethon::Easy do
  let(:easy) { Ethon::Easy.new }

  describe ".new" do
    it "inits curl" do
      Ethon::Curl.should_receive(:init)
      easy
    end

    it "defines finalizer" do
      ObjectSpace.should_receive(:define_finalizer)
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
            expect(value).to be(1)
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

  describe ".finalizer" do
    it "calls easy_cleanup" do
      Ethon::Curl.should_receive(:easy_cleanup).with(easy.handle)
      Ethon::Easy.finalizer(easy).call
    end

    context "when header_list" do
      before { easy.instance_variable_set(:@header_list, 1) }

      it "calls slist_free_all" do
        Ethon::Curl.should_receive(:slist_free_all).with(easy.header_list)
        Ethon::Easy.finalizer(easy).call
      end
    end
  end
end
