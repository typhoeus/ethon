require 'spec_helper'

describe Orthos::Multies::Stack do
  let(:multi) { Orthos::Multi.new }
  let(:easy) { Orthos::Easy.new }

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
end
