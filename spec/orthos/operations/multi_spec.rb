require 'spec_helper'

describe Orthos::Operations::Multi do
  let(:multi) { Orthos::Multi.new }
  let(:easy) { Orthos::Easy.new }

  describe "#running_count" do
    context "when hydra has no easy" do
      it "returns nil" do
        multi.running_count.should be_nil
      end
    end

    context "when hydra has easy" do
      before do
        easy.url = "http://localhost:3001/"
        easy.prepare
        multi.add(easy)
        multi.trigger
      end

      it "returns 1" do
        multi.running_count.should eq(1)
      end
    end

    context "when hydra has more easys" do
      let(:another_easy) { Orthos::Easy.new }

      before do
        easy.url = "http://localhost:3001/"
        easy.prepare
        another_easy.url = "http://localhost:3001/"
        another_easy.prepare
        multi.add(easy)
        multi.add(another_easy)
        multi.trigger
      end

      it "returns 2" do
        multi.running_count.should eq(2)
      end
    end
  end

  describe "#run" do
    it
  end

  describe "#trigger" do
    it
  end

  describe "#perform" do
    context "when no easy handles" do
      it "returns nil" do
        multi.perform.should be_nil
      end
    end

    context "when easy handle" do
      before do
        easy.url = "http://localhost:3001/"
        easy.prepare
        multi.add(easy)
      end

      it "requests" do
        multi.perform
      end

      it "sets easy" do
        multi.perform
        easy.response_code.should eq(200)
      end
    end

    context "when four easy handles" do
      let(:easies) do
        ary = []
        4.times do
          ary << another_easy = Orthos::Easy.new
          another_easy.url = "http://localhost:3001/"
          another_easy.prepare
        end
        ary
      end

      before do
        easies.each { |e| multi.add(e) }
        multi.perform
      end

      it "sets response codes" do
        easies.all?{ |e| e.response_code == 200 }.should be_true
      end
    end
  end
end
