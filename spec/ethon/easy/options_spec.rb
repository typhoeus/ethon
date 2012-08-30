require 'spec_helper'

describe Ethon::Easy::Options do
  let(:easy) { Ethon::Easy.new }

  describe "options" do
    let(:options) { Ethon::Easy.available_options }
    let(:bool_options) { Ethon::Easy.bool_options }
    let(:enum_options) { Ethon::Easy.enum_options }
    let(:int_options) { Ethon::Easy.int_options }
    let(:unspecific_options) { options - bool_options - enum_options.keys - int_options }

    it "have read accessors" do
      expect(options.all? { |o| easy.respond_to?(o) }).to be_true
    end

    it "have write accessors" do
      expect(options.all? { |o| easy.respond_to?("#{o}=") }).to be_true
    end

    context "when option in bool_options" do
      context "when value true" do
        it "sets" do
          bool_options.each { |o| easy.method("#{o}=").call(true); easy.prepare }
        end
      end

      context "when value false" do
        it "sets" do
          bool_options.each { |o| easy.method("#{o}=").call(false); easy.prepare }
        end
      end
    end

    context "when option in enum_options" do
      context "when invalid value" do
        it "raises invalid value error" do
          easy.httpauth = :invalid
          expect{ easy.prepare }.to raise_error(Ethon::Errors::InvalidValue)
        end
      end

      context "when valid value" do
        it "sets" do
          easy.httpauth = :basic
          easy.prepare
        end
      end
    end

    context "when option in int_options" do
      it "sets" do
        int_options.each { |o| easy.method("#{o}=").call(1); easy.prepare }
      end
    end

    context "when option unspecific" do
      it "sets" do
        unspecific_options.each { |o| easy.method("#{o}=").call("hello"); easy.prepare }
      end
    end
  end

  describe "#set_options" do
    let(:url) { "http://localhost:3001/" }

    context "when option" do
      it "sets curl option" do
        easy.url = url
        Ethon::Curl.should_receive(:set_option).at_least(:once)
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
        Ethon::Curl.should_receive(:set_option).at_least(:once)
        easy.set_options
      end
    end
  end

  describe "#value_for" do
    before { easy.method("#{option}=").call(value) }

    context "when option in bool_options" do
      let(:option) { :verbose }

      context "when value true" do
        let(:value) { true }

        it "returns 1" do
          expect(easy.value_for(option)).to eq(1)
        end
      end

      context "when value false" do
        let(:value) { false }

        it "returns 0" do
          expect(easy.value_for(option)).to eq(0)
        end
      end
    end

    context "when value in enum_options" do
      let(:option) { :httpauth }
      let(:value) { :ntlm }

      it "returns value from struct" do
        expect(easy.value_for(option)).to eq(8)
      end
    end

    context "when value in int_options" do
      let(:option) { :maxredirs }
      let(:value) { "2" }

      it "returns value casted to int" do
        expect(easy.value_for(option)).to eq(2)
      end
    end

    context "when value in unspecific_options" do
      let(:option) { :url }
      context "when value a string" do
        let(:value) { "www.example.\0com" }

        it "returns zero byte escaped string" do
          expect(easy.value_for(option)).to eq("www.example.\\0com")
        end
      end

      context "when value not a string" do
        let(:value) { 1 }

        it "returns value" do
          expect(easy.value_for(option)).to eq(1)
        end
      end
    end
  end

  context "when requesting" do
    let(:url) { "localhost:3001" }
    let(:timeout) { nil }
    let(:timeout_ms) { nil }
    let(:connecttimeout) { nil }
    let(:connecttimeout_ms) { nil }

    before do
      easy.url = url
      easy.timeout = timeout
      easy.timeout_ms = timeout_ms
      easy.connecttimeout = connecttimeout
      easy.connecttimeout_ms = connecttimeout_ms
      easy.prepare
      easy.perform
    end

    context "when timeout" do
      let(:timeout) { 1 }

      context "when request takes longer" do
        let(:url) { "localhost:3001?delay=2" }

        it "times out" do
          expect(easy.return_code).to eq(:operation_timedout)
        end
      end
    end

    context "when connecttimeout" do
      let(:connecttimeout) { 1 }

      context "when cannot connect" do
        let(:url) { "localhost:3002" }

        it "times out" do
          expect(easy.return_code).to eq(:couldnt_connect)
        end
      end
    end

    if Ethon::Curl.version.match("c-ares")
      context "when timeout_ms" do
        let(:timeout_ms) { 900 }

        context "when request takes longer" do
          let(:url) { "localhost:3001?delay=1" }

          it "times out" do
            expect(easy.return_code).to eq(:operation_timedout)
          end
        end
      end

      context "when connecttimeout_ms" do
        let(:connecttimeout_ms) { 1 }

        context "when cannot connect" do
          let(:url) { "localhost:3002" }

          it "times out" do
            expect(easy.return_code).to eq(:couldnt_connect)
          end
        end
      end
    end
  end
end
