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
end
