# frozen_string_literal: true
require 'spec_helper'
require 'tmpdir'

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

      it "keeps the previous response" do
        easy.url = "http://127.0.0.1:3001/"
        easy.perform
        body = easy.response_body
        headers = easy.response_headers

        allow(Ethon::Curl).to receive(:multi_add_handle).and_return(:bad_easy_handle)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::MultiAdd)
        expect(easy.response_body).to equal(body)
        expect(easy.response_headers).to equal(headers)
      end

      it "does not start a new transfer state" do
        easy.url = "http://127.0.0.1:3001/"
        easy.perform
        allow(Ethon::Curl).to receive(:multi_add_handle).and_return(:bad_easy_handle)

        expect(easy).not_to receive(:reset_transfer_state)
        expect(easy).not_to receive(:clear_callback_error)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::MultiAdd)
      end
    end

    context "when the easy is performing its own transfer" do
      it "does not interrupt the transfer when the add is rejected" do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "body")
          easy.url = "http://127.0.0.1:3001/"
          easy.file = path
          error = nil
          easy.on_body do |_chunk|
            error ||= begin
              multi.add(easy)
              nil
            rescue Exception => e
              e
            end
            true
          end

          expect(easy.perform).to eq(:ok)

          expect(error).to be_a(Ethon::Errors::MultiAdd)
          expect(error.message).to match(/added_already/)
          expect(File.binread(path)).to include('"REQUEST_METHOD":"GET"')
          expect(easy.instance_variable_get(:@response_body_io)).to be_nil
        end
      end
    end

    context "when the easy does not belong to this library" do
      it "raises a type error" do
        other_multi = Ethon::Multi.new

        expect { multi.add(other_multi) }.
          to raise_error(TypeError, /Ethon::Easy/)
        expect(multi.easy_handles).to be_empty
      ensure
        other_multi.cleanup if other_multi && !other_multi.instance_variable_get(:@cleaned_up)
      end
    end

    context "when preparing the transfer fails" do
      it "detaches the handle again" do
        easy.url = "http://127.0.0.1:3001/"
        error = Errno::ENOENT.new("response body")
        allow(easy).to receive(:prepare_response_body_io).and_raise(error)

        expect { multi.add(easy) }.to raise_error(error)

        expect(multi.easy_handles).not_to include(easy)
        expect(easy.instance_variable_get(:@multi)).to be_nil
        if Ethon::Curl.respond_to?(:multi_get_handles)
          expect(multi.native_handles).to be_empty
        end

        allow(easy).to receive(:prepare_response_body_io).and_call_original
        expect(easy.perform).to eq(:ok)
      end

      it "keeps the previous response" do
        easy.url = "http://127.0.0.1:3001/"
        easy.perform
        body = easy.response_body

        allow(easy).to receive(:prepare_response_body_io).and_raise(Errno::EACCES)

        expect { multi.add(easy) }.to raise_error(Errno::EACCES)
        expect(easy.response_body).to equal(body)
      end

      it "keeps the handle tracked when detaching fails" do
        easy.url = "http://127.0.0.1:3001/"
        allow(easy).to receive(:prepare_response_body_io).and_raise(Errno::EACCES)
        allow(Ethon::Curl).to receive(:multi_remove_handle).and_return(:out_of_memory)

        expect { multi.add(easy) }.to raise_error(Errno::EACCES)
        expect(multi.easy_handles).to include(easy)
        expect(easy.instance_variable_get(:@multi)).to be(multi)
      ensure
        allow(Ethon::Curl).to receive(:multi_remove_handle).and_call_original
        easy.instance_variable_get(:@multi) && multi.delete(easy)
        easy.cleanup if easy && !easy.instance_variable_get(:@cleaned_up)
      end
    end

    context "when easy.handle raises" do
      it "does not track the easy" do
        allow(easy).to receive(:handle).and_raise(Ethon::Errors::ForkSafety.new)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::ForkSafety)
        expect(multi.easy_handles).not_to include(easy)
      end
    end

    context "when the easy is attached to another multi" do
      let(:other_multi) { Ethon::Multi.new }
      let(:tempfile) { Tempfile.new("ethon-multi-attach") }

      after { tempfile.close! }

      before do
        easy.url = "http://127.0.0.1:3001/"
        multi.add(easy)
      end

      it "raises without taking over the handle" do
        expect { other_multi.add(easy) }.
          to raise_error(Ethon::Errors::EthonError, /attached to a Multi/)

        expect(multi.easy_handles).to include(easy)
        expect(other_multi.easy_handles).not_to include(easy)
        expect(easy.instance_variable_get(:@multi)).to be(multi)
      end

      it "leaves the existing multi transfer usable" do
        easy.file = tempfile.path
        tempfile.close

        expect { other_multi.add(easy) }.
          to raise_error(Ethon::Errors::EthonError, /attached to a Multi/)

        multi.perform

        expect(easy.return_code).to eq(:ok)
        expect(File.binread(tempfile.path)).to include('"REQUEST_METHOD":"GET"')
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

      it "detaches a handle that libcurl attached before the callback raised" do
        local_multi = Ethon::Multi.new(:execution_mode => :socket_action)
        local_multi.timerfunction = proc { "hi" }
        local_easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")

        expect { local_multi.add(local_easy) }.
          to raise_error(ArgumentError, /invalid enum value/)

        expect(local_multi.easy_handles).not_to include(local_easy)
        expect(local_easy.instance_variable_get(:@multi)).to be_nil
        if Ethon::Curl.respond_to?(:multi_get_handles)
          expect(local_multi.native_handles).to be_empty
        end
      ensure
        local_multi.timerfunction = proc { 0 } if local_multi
        local_multi.cleanup if local_multi && !local_multi.instance_variable_get(:@cleaned_up)
        local_easy.cleanup if local_easy && !local_easy.instance_variable_get(:@cleaned_up)
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

      it "does not truncate the response file when adding fails" do
        easy.url = "http://127.0.0.1:3001/"
        easy.file = tempfile.path
        easy.perform
        written = File.binread(tempfile.path)
        expect(written).not_to be_empty
        expect(Ethon::Curl).to receive(:multi_add_handle).and_return(:bad_easy_handle)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::MultiAdd)

        expect(File.binread(tempfile.path)).to eq(written)
        expect(easy.instance_variable_get(:@response_body_io)).to be_nil
      end

      it "does not touch an open response stream when adding fails" do
        easy.file = tempfile.path
        io = easy.instance_variable_get(:@response_body_io)
        expect(Ethon::Curl).to receive(:multi_add_handle).and_return(:bad_easy_handle)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::MultiAdd)
        expect(io).not_to be_closed
      end

      it "leaves an open stream alone when the easy handle is unusable" do
        easy.file = tempfile.path
        io = easy.instance_variable_get(:@response_body_io)
        allow(easy).to receive(:handle).and_raise(Ethon::Errors::ForkSafety.new)

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::ForkSafety)
        expect(io).not_to be_closed
      end

      it "leaves an open stream alone when the multi was cleaned up" do
        easy.file = tempfile.path
        io = easy.instance_variable_get(:@response_body_io)
        multi.cleanup

        expect { multi.add(easy) }.to raise_error(Ethon::Errors::EthonError, /cleaned up/)
        expect(io).not_to be_closed
      end

      it "opens the response file for a successful add" do
        easy.url = "http://127.0.0.1:3001/"
        easy.file = tempfile.path

        multi.add(easy)

        expect(easy.instance_variable_get(:@response_body_io)).not_to be_nil
        expect(File.size(tempfile.path)).to eq(0)
      ensure
        multi.delete(easy) if easy && multi.easy_handles.include?(easy)
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
