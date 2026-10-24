# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::ResponseCallbacks do
  let(:easy) { Ethon::Easy.new }

  [:on_complete, :on_headers, :on_body, :on_progress].each do |callback_type|
    describe "##{callback_type}" do
      it "responds" do
        expect(easy).to respond_to("#{callback_type}")
      end

      context "when no block given" do
        it "returns @#{callback_type}" do
          expect(easy.send("#{callback_type}")).to eq([])
        end
      end

      context "when block given" do
        it "stores" do
          easy.send(callback_type) { p 1 }
          expect(easy.instance_variable_get("@#{callback_type}").size).to eq(1)
        end
      end

      context "when multiple blocks given" do
        it "stores" do
          easy.send(callback_type) { p 1 }
          easy.send(callback_type) { p 2 }
          expect(easy.instance_variable_get("@#{callback_type}").size).to eq(2)
        end
      end
    end
  end

  describe "#complete" do
    before do
      easy.on_complete {|r| String.new(r.url) }
    end

    it "executes blocks and passes self" do
      expect(String).to receive(:new).with(easy.url)
      easy.complete
    end

    context "when @on_complete nil" do
      it "doesn't raise" do
        easy.instance_variable_set(:@on_complete, nil)
        expect{ easy.complete }.to_not raise_error
      end
    end

    it "refuses to complete recursively from an on_complete callback" do
      easy.on_complete.clear
      easy.on_complete { easy.complete }

      expect { easy.complete }.
        to raise_error(Ethon::Errors::EthonError, /already completing/)
    end

    it "refuses to complete recursively from an on_headers callback" do
      easy.on_complete.clear
      easy.response_headers = "HTTP/1.1 200 OK\r\n"
      easy.on_headers { easy.complete }

      expect { easy.complete }.
        to raise_error(Ethon::Errors::EthonError, /already completing/)
    end
  end

  describe "#headers" do
    before do
      easy.on_headers {|r| String.new(r.url) }
    end

    it "executes blocks and passes self" do
      expect(String).to receive(:new).with(easy.url)
      easy.headers
    end

    context "when @on_headers nil" do
      it "doesn't raise" do
        easy.instance_variable_set(:@on_headers, nil)
        expect{ easy.headers }.to_not raise_error
      end
    end
  end

  describe "#progress" do
    context "when requesting for realz" do
      it "executes callback" do
        post = Ethon::Easy::Http::Post.new("http://localhost:3001", {:body => "bar=fu"})
        post.setup(easy)
        @called = false
        @has_dltotal = false
        @has_ultotal = false
        easy.on_progress { @called = true }
        easy.on_progress { |dltotal, _, _, _| @has_dltotal ||= true }
        easy.on_progress { |_, _, ultotal, _| @has_ultotal ||= true }
        easy.perform
        expect(@called).to be true
        expect(@has_dltotal).to be true
        expect(@has_ultotal).to be true
      end
    end

    context "when pretending" do
      before do
        @dltotal = nil
        @dlnow = nil
        @ultotal = nil
        @ulnow = nil
        easy.on_progress { |dltotal, dlnow, ultotal, ulnow| @dltotal = dltotal ; @dlnow = dlnow; @ultotal = ultotal; @ulnow = ulnow }
      end

      it "executes blocks and passes dltotal" do
        easy.progress(1, 2, 3, 4)
        expect(@dltotal).to eq(1)
      end

      it "executes blocks and passes dlnow" do
        easy.progress(1, 2, 3, 4)
        expect(@dlnow).to eq(2)
      end

      it "executes blocks and passes ultotal" do
        easy.progress(1, 2, 3, 4)
        expect(@ultotal).to eq(3)
      end

      it "executes blocks and passes ulnow" do
        easy.progress(1, 2, 3, 4)
        expect(@ulnow).to eq(4)
      end

      context "when @on_progress nil" do
        it "doesn't raise" do
          easy.instance_variable_set(:@on_progress, nil)
          expect{ easy.progress(1, 2, 3, 4) }.to_not raise_error
        end
      end
    end
  end

  describe "#body" do
    before do
      @chunk = nil
      @r = nil
      easy.on_body { |chunk, r| @chunk = chunk ; @r = r }
    end

    it "executes blocks and passes self" do
      easy.body("the chunk")
      expect(@r).to be(easy)
    end

    it "executes blocks and passes chunk" do
      easy.body("the chunk")
      expect(@chunk).to eq("the chunk")
    end

    context "when @on_body nil" do
      it "doesn't raise" do
        easy.instance_variable_set(:@on_body, nil)
        expect{ easy.body("the chunk") }.to_not raise_error
      end
    end

    context "when no on_body block was ever given" do
      it "returns :unyielded" do
        expect(Ethon::Easy.new.body("the chunk")).to eq(:unyielded)
      end
    end

    context "when the callback list is empty" do
      before { easy.on_body.clear }

      it "returns :unyielded" do
        expect(easy.body("the chunk")).to eq(:unyielded)
      end
    end
  end

  describe "response body buffering" do
    it "still buffers the body when #on_body is only read" do
      easy.url = "http://localhost:3001/"

      easy.on_body
      easy.perform

      expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
    end

    it "still buffers the body after the on_body list is cleared" do
      easy.url = "http://localhost:3001/"

      easy.on_body { |_chunk| }
      easy.on_body.clear
      easy.perform

      expect(easy.response_body).to include('"REQUEST_METHOD":"GET"')
    end
  end
end
