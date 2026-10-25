# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::Slist do
  describe ".build" do
    it "returns nil without lines" do
      expect(described_class.build([])).to be_nil
    end

    it "builds a list from lines" do
      list = described_class.build(["X-First: 1", "X-Second: 2"])

      expect(described_class.new(list).to_a).
        to eq(["X-First: 1", "X-Second: 2"])
    end

    it "frees the previous list and raises when an append fails" do
      first = FFI::MemoryPointer.new(:pointer)
      allow(Ethon::Curl).to receive(:slist_append).and_return(first, FFI::Pointer::NULL)
      expect(Ethon::Curl).to receive(:slist_free_all).with(first)

      expect { described_class.build(["one", "two"]) }.
        to raise_error(NoMemoryError, "curl_slist_append failed")
    end
  end
end

describe "native pointer ownership" do
  it "rejects wrapping the same easy pointer twice" do
    easy = Ethon::Easy.new

    expect { Ethon::Curl::EasyHandle.new(FFI::Pointer.new(easy.handle.address)) }.
      to raise_error(ArgumentError, /already owned/)
  ensure
    easy.cleanup if easy
  end

  it "rejects assigning another Easy's raw handle" do
    owner = Ethon::Easy.new
    other = Ethon::Easy.new

    own_handle = other.handle
    expect { other.handle = FFI::Pointer.new(owner.handle.address) }.
      to raise_error(ArgumentError, /already owned/)
    expect(other.handle).to be(own_handle)
  ensure
    owner.cleanup if owner
    other.cleanup if other
  end

  it "rejects assigning another Easy's owned wrapper" do
    owner = Ethon::Easy.new
    other = Ethon::Easy.new

    own_handle = other.handle
    expect { other.handle = owner.handle }.
      to raise_error(ArgumentError, /already owned/)
    expect(other.handle).to be(own_handle)
  ensure
    owner.cleanup if owner
    other.cleanup if other
  end

  it "rejects wrapping an owned slist pointer twice" do
    list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))

    expect { Ethon::Curl::Slist.new(FFI::Pointer.new(list.address)) }.
      to raise_error(ArgumentError, /already owned/)
  ensure
    list.free if list
  end

  it "rejects wrapping an owned URL pointer twice" do
    url = Ethon::Curl::Url.new("https://example.com/")

    expect { Ethon::Curl::Url.new(FFI::Pointer.new(url.address)) }.
      to raise_error(ArgumentError, /already owned/)
  ensure
    url.free if url
  end

  it "does not reserve an address when wrapping fails" do
    pointer = FFI::MemoryPointer.new(:int)

    expect { Ethon::Curl::EasyHandle.new(pointer) }.to raise_error(TypeError)
    expect(Ethon::Curl::OwnedPointer.owners).not_to have_key(pointer.address)
  end
end

describe "explicitly freed owned pointers" do
  def freed_error
    Ethon::Errors::EthonError
  end

  it "rejects a freed slist" do
    list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))
    list.free

    expect { list.to_a }.to raise_error(freed_error, /freed/)
  end

  it "rejects a freed URL handle" do
    url = Ethon::Curl::Url.new("https://example.com/")
    url.free

    expect { url.to_s }.to raise_error(freed_error, /freed/)
  end

  it "rejects a freed MIME structure and its parts" do
    easy = Ethon::Easy.new
    mime = Ethon::Curl::Mime.new(easy)
    part = mime.addpart
    mime.free

    expect { part.name = "field" }.to raise_error(freed_error, /freed/)
  ensure
    easy.cleanup if easy
  end

  it "rejects a freed share handle" do
    share = Ethon::Curl::Share.new
    share.free

    expect { share.share(:cookie) }.to raise_error(freed_error, /freed/)
  end

  it "rejects a freed Easy handle" do
    easy = Ethon::Easy.new
    easy.handle.free

    expect { easy.perform }.to raise_error(freed_error, /freed/)
  ensure
    easy.instance_variable_set(:@handle, nil) if easy
  end

  it "rejects a freed Multi handle" do
    multi = Ethon::Multi.new
    multi.handle.free

    expect { multi.wait }.to raise_error(freed_error, /freed/)
  ensure
    multi.instance_variable_set(:@handle, nil) if multi
  end
end

describe Ethon::Curl::FDSet do
  it "uses a word-aligned fd_set size" do
    skip "Windows uses a fixed fd_array" if Ethon::Curl.windows?

    expect(described_class::FD_SETSIZE % FFI::Type::LONG.size).to eq(0)
  end
end

describe Ethon::Curl::EasyHandle do
  it "shares one owner registry with the other owned pointer types" do
    expect(described_class.owners).to be(Ethon::Curl::OwnedPointer.owners)
    expect(Ethon::Curl::MultiHandle.owners).to be(Ethon::Curl::OwnedPointer.owners)
    expect(Ethon::Curl::Slist.owners).to be(Ethon::Curl::OwnedPointer.owners)
  end

  it "registers every owned pointer type in that registry" do
    easy = Ethon::Easy.new
    list = Ethon::Curl::Slist.new(Ethon::Curl::Slist.build(["X-Test: 1"]))

    expect(Ethon::Curl::OwnedPointer.owners).to have_key(easy.handle.address)
    expect(Ethon::Curl::OwnedPointer.owners).to have_key(list.address)
  ensure
    easy.cleanup if easy
    list.free if list
  end

  describe ".release" do
    let(:pointer) { double(:address => 4242) }

    after { described_class.owners.delete(pointer.address) }

    it "frees a pointer owned by the current process" do
      described_class.owners[pointer.address] = Process.pid

      expect(described_class).to receive(:native_release).with(pointer)

      described_class.release(pointer)
    end

    it "does not free a pointer inherited from another process" do
      described_class.owners[pointer.address] = Process.pid + 1

      expect(described_class).not_to receive(:native_release)

      described_class.release(pointer)
    end

    it "does not free an unknown pointer" do
      expect(described_class).not_to receive(:native_release)

      described_class.release(pointer)
    end

    it "still frees when the owners mutex cannot be used" do
      described_class.owners[pointer.address] = Process.pid
      allow(described_class::OWNERS_MUTEX).to receive(:synchronize).and_raise(ThreadError)

      expect(described_class).to receive(:native_release).with(pointer)

      described_class.release(pointer)
    end

    it "still frees when a signal interrupts the finalizer" do
      described_class.owners[pointer.address] = Process.pid
      allow(described_class::OWNERS_MUTEX).to receive(:synchronize).and_raise(SignalException.new("TERM"))

      expect(described_class).to receive(:native_release).with(pointer)

      described_class.release(pointer)
    end
  end
end
