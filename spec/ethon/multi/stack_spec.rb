# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Multi::Stack do
  let(:multi) { Ethon::Multi.new }
  let(:easy) { Ethon::Easy.new }

  describe "#add" do
    context "when easy already added" do
      before { multi.add(easy) }
      after { multi.delete(easy) }

      it "returns nil" do
        expect(multi.add(easy)).to be_nil
      end
    end

    context "when easy new" do
      it "adds easy to multi" do
        expect(Ethon::Curl).to receive(:multi_add_handle).and_return(:ok)
        multi.add(easy)
        multi.easy_handles.delete(easy)
      end

      it "adds easy to easy_handles" do
        multi.add(easy)
        expect(multi.easy_handles).to include(easy)
        multi.delete(easy)
      end
    end

    context "when multi_add_handle fails" do
      it "raises multi add error" do
        expect(Ethon::Curl).to receive(:multi_add_handle).and_return(:bad_easy_handle)
        expect{ multi.add(easy) }.to raise_error(Ethon::Errors::MultiAdd)
        expect(multi.easy_handles).to_not include(easy)
      end
    end

    context "when a callback raises while adding" do
      it "keeps the easy tracked" do
        error = RuntimeError.new("callback failed")
        expect(Ethon::Curl).to receive(:multi_add_handle) do
          expect(multi.easy_handles).to include(easy)
          raise error
        end

        expect { multi.add(easy) }.to raise_error(error)
        expect(multi.easy_handles).to include(easy)
        multi.easy_handles.delete(easy)
      end
    end

  end

  describe "#delete" do
    context "when easy in easy_handles" do
      before { multi.add(easy) }

      it "deletes easy from multi" do
        expect(Ethon::Curl).to receive(:multi_remove_handle).and_call_original
        multi.delete(easy)
      end

      it "deletes easy from easy_handles" do
        multi.delete(easy)
        expect(multi.easy_handles).to_not include(easy)
      end
    end

    context "when easy is not in easy_handles" do
      it "does nothing" do
        expect(Ethon::Curl).to receive(:multi_add_handle).and_return(:ok)
        multi.add(easy)
        multi.easy_handles.delete(easy)
      end

      it "adds easy to easy_handles" do
        multi.add(easy)
        expect(multi.easy_handles).to include(easy)
        multi.delete(easy)
      end
    end

    context "when multi_remove_handle fails" do
      before { multi.easy_handles << easy }

      it "raises multi remove error" do
        expect(Ethon::Curl).to receive(:multi_remove_handle).and_return(:bad_easy_handle)
        expect{ multi.delete(easy) }.to raise_error(Ethon::Errors::MultiRemove)
        expect(multi.easy_handles).to include(easy)
        multi.easy_handles.delete(easy)
      end
    end

    context "when a callback raises while removing" do
      before { multi.easy_handles << easy }

      it "keeps the easy removed" do
        error = RuntimeError.new("callback failed")
        expect(Ethon::Curl).to receive(:multi_remove_handle) do
          expect(multi.easy_handles).to_not include(easy)
          raise error
        end

        expect { multi.delete(easy) }.to raise_error(error)
        expect(multi.easy_handles).to_not include(easy)
      end
    end
  end
end
