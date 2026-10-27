# frozen_string_literal: true
require 'spec_helper'
require 'tempfile'

describe "Ethon::Multi#cleanup failures" do
  let(:multi) { Ethon::Multi.new }
  let(:easy) { Ethon::Easy.new }

  it "releases the native handle when detaching an easy fails" do
    easy.url = "http://127.0.0.1:3001/"
    multi.add(easy)
    allow(Ethon::Curl).to receive(:multi_remove_handle).and_return(:bad_easy_handle)

    expect { multi.cleanup }.to raise_error(Ethon::Errors::MultiRemove)
    expect(multi.instance_variable_get(:@handle)).to be_nil
    expect(multi.instance_variable_get(:@cleaned_up)).to be(true)
    expect(multi.easy_handles).to be_empty
    expect(easy.instance_variable_get(:@multi)).to be(multi)
    expect { easy.perform }.
      to raise_error(Ethon::Errors::EthonError, /attached to a Multi/)
  end

  it "keeps tearing down when closing a streamed response fails" do
    easy.url = "http://127.0.0.1:3001/"
    multi.add(easy)
    allow(Ethon::Curl).to receive(:multi_remove_handle).and_return(:bad_easy_handle)
    allow(easy).to receive(:finish_response_body_io).and_raise(IOError, "close failed")

    expect { multi.cleanup }.to raise_error(Ethon::Errors::MultiRemove)
    expect(multi.instance_variable_get(:@cleaned_up)).to be(true)
    expect(multi.easy_handles).to be_empty
  end

  it "detaches the remaining handles when closing a streamed response fails" do
    first = Ethon::Easy.new
    second = Ethon::Easy.new

    Tempfile.create("ethon-cleanup-first") do |first_file|
      Tempfile.create("ethon-cleanup-second") do |second_file|
        first.file = first_file.path
        second.file = second_file.path
        multi.add(first)
        multi.add(second)

        allow(first).to receive(:finish_response_body_io).and_raise(IOError, "close failed")

        expect { multi.cleanup }.to raise_error(IOError, "close failed")
        expect(multi.easy_handles).to be_empty
        expect(first.instance_variable_get(:@multi)).to be_nil
        expect(second.instance_variable_get(:@multi)).to be_nil
        expect(second.instance_variable_get(:@response_body_io)).to be_nil
      ensure
        # The stubbed teardown leaves the first stream open. Windows cannot
        # delete a file while it is still open.
        first.clear_response_body_io
      end
    end
  end

  it "detaches the remaining handles when one native detach fails" do
    first = Ethon::Easy.new
    second = Ethon::Easy.new
    multi.add(first)
    multi.add(second)

    calls = 0
    allow(Ethon::Curl).to receive(:multi_remove_handle).and_wrap_original do |original, handle, easy_handle|
      calls += 1
      calls == 1 ? :bad_easy_handle : original.call(handle, easy_handle)
    end

    expect { multi.cleanup }.to raise_error(Ethon::Errors::MultiRemove)
    expect(calls).to eq(2)
    expect(multi.easy_handles).to be_empty
    expect(first.instance_variable_get(:@multi)).to be(multi)
    expect(second.instance_variable_get(:@multi)).to be_nil
  end
end
