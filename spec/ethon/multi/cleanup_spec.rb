# frozen_string_literal: true
require 'spec_helper'

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
    expect(easy.instance_variable_get(:@multi)).to be_nil
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
end
