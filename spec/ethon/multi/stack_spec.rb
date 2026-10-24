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

    context "when easy.handle raises" do
      it "does not track the easy" do
        allow(easy).to receive(:handle).and_raise(Ethon::Errors::ForkSafety.new)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::ForkSafety)
        expect(multi.easy_handles).not_to include(easy)
      end
    end

    context "when a callback raises while adding" do
      it "does not keep the easy tracked" do
        error = RuntimeError.new("callback failed")
        expect(Ethon::Curl).to receive(:multi_add_handle) do
          expect(multi.easy_handles).to include(easy)
          raise error
        end

        expect { multi.add(easy) }.to raise_error(error)
        expect(multi.easy_handles).not_to include(easy)
      end
    end

    it "records the multi on the easy" do
      multi.add(easy)

      expect(easy.instance_variable_get(:@multi)).to be(multi)
    ensure
      multi.delete(easy) if multi.easy_handles.include?(easy)
    end

    context "when streaming the response to a file" do
      let(:tempfile) { Tempfile.new("ethon-multi-add") }
      after { tempfile.close! }

      it "closes the file when adding fails" do
        easy.file = tempfile.path
        easy.prepare_response_body_io
        io = easy.instance_variable_get(:@response_body_io)
        expect(Ethon::Curl).to receive(:multi_add_handle).and_return(:bad_easy_handle)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::MultiAdd)
        expect(io).to be_closed
      end

      it "closes the file when the easy handle is unusable" do
        easy.file = tempfile.path
        easy.prepare_response_body_io
        io = easy.instance_variable_get(:@response_body_io)
        allow(easy).to receive(:handle).and_raise(Ethon::Errors::ForkSafety.new)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::ForkSafety)
        expect(io).to be_closed
      end

      it "closes the file when the multi was cleaned up" do
        easy.file = tempfile.path
        easy.prepare_response_body_io
        io = easy.instance_variable_get(:@response_body_io)
        multi.cleanup

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::EthonError, /cleaned up/)
        expect(io).to be_closed
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

      it "clears the multi on the easy" do
        multi.delete(easy)

        expect(easy.instance_variable_get(:@multi)).to be_nil
      end

    end

    context "when streaming the response to a file" do
      let(:tempfile) { Tempfile.new("ethon-multi-delete") }
      after { tempfile.close! }

      before do
        easy.file = tempfile.path
        multi.add(easy)
      end

      it "closes the file" do
        io = easy.instance_variable_get(:@response_body_io)

        multi.delete(easy)

        expect(io).to be_closed
      end
    end

    context "when easy is not in easy_handles" do
      it "does nothing" do
        expect(Ethon::Curl).not_to receive(:multi_remove_handle)

        expect(multi.delete(easy)).to be_nil
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

      it "keeps the easy tracked" do
        error = RuntimeError.new("callback failed")
        expect(Ethon::Curl).to receive(:multi_remove_handle) do
          expect(multi.easy_handles).to_not include(easy)
          raise error
        end

        expect { multi.delete(easy) }.to raise_error(error)
        expect(multi.easy_handles).to include(easy)
        multi.easy_handles.delete(easy)
      end
    end
  end
end
