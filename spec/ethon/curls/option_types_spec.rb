# frozen_string_literal: true
require 'spec_helper'

describe "Ethon option types" do
  let!(:easy) { Ethon::Easy.new }

  it "escapes null bytes for string_escape_null options" do
    allow(Ethon::Curl).to receive(:easy_options).and_return(
      :synthetic_escape => {
        :type => :string_escape_null,
        :opt => 30_123,
        :opts => nil
      }
    )
    expect(Ethon::Curl).to receive(:easy_setopt).
      with(easy.handle, 30_123, :string, "a\\0b").and_return(:ok)

    Ethon::Curl.set_option(:synthetic_escape, "a\0b", easy.handle)
  end

  describe "string_as_pointer options" do
    it "passes a NULL pointer for nil" do
      expect(Ethon::Curl).to receive(:easy_setopt).
        with(easy.handle, anything, :pointer, nil).and_return(:ok)

      Ethon::Curl.set_option(:copypostfields, nil, easy.handle)
    end

    it "NUL-terminates the copied string" do
      pointer = nil
      allow(Ethon::Curl).to receive(:easy_setopt) do |_handle, _option, _type, value|
        pointer = value
        :ok
      end

      Ethon::Curl.set_option(:copypostfields, "a\0b", easy.handle)

      expect(pointer).to be_a(FFI::MemoryPointer)
      expect(pointer.size).to eq(4)
      expect(pointer.read_bytes(4)).to eq("a\0b\0".b)
    end
  end
end
