# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl do
  it "uses the native socket type on Unix" do
    skip "Windows uses SOCKET" if described_class.windows?

    socket_type = described_class.find_type(:curl_socket_t)

    expect(FFI.type_size(socket_type)).to eq(FFI.type_size(:int))
  end
end
