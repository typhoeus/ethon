require 'spec_helper'

describe Orthos::Multi do
  let(:multi) { Orthos::Multi.new }
  let(:easy) { Orthos::Easy.new }

  describe ".new" do
    it "inits curl" do
      Orthos::Curl.expects(:init)
      multi
    end

    it "defines finalizer" do
      ObjectSpace.expects(:define_finalizer)
      multi
    end
  end

  describe "#handle" do
    it "returns a pointer" do
      multi.handle.should be_a(FFI::Pointer)
    end
  end

  describe "#add" do
    context "when easy already added" do
      before { multi.add(easy) }

      it "returns nil" do
        multi.add(easy).should be_nil
      end
    end

    context "when easy new" do
      it "adds easy to multi" do
        Orthos::Curl.expects(:multi_add_handle)
        multi.add(easy)
      end

      it "adds easy to easy_handles" do
        multi.add(easy)
        multi.easy_handles.should include(easy)
      end
    end
  end

  describe "#delete" do
    context "when easy in easy_handles" do
      before { multi.add(easy) }

      it "deletes easy from multi" do
        Orthos::Curl.expects(:multi_remove_handle)
        multi.delete(easy)
      end

      it "deletes easy from easy_handles" do
        multi.delete(easy)
        multi.easy_handles.should_not include(easy)
      end
    end

    context "when easy is not in easy_handles" do
      it "does nothing" do
        Orthos::Curl.expects(:multi_add_handle)
        multi.add(easy)
      end

      it "adds easy to easy_handles" do
        multi.add(easy)
        multi.easy_handles.should include(easy)
      end
    end
  end

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
