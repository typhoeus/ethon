# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::ShareCode do
  it "maps the codes" do
    expect(described_class[:ok]).to eq(0)
    expect(described_class[:bad_option]).to eq(1)
    expect(described_class[:not_built_in]).to eq(5)
    expect(described_class[:last]).to eq(6)
  end
end

describe Ethon::Curl::ShareOption do
  it "maps the options" do
    expect(described_class[:share]).to eq(1)
    expect(described_class[:unshare]).to eq(2)
    expect(described_class[:userdata]).to eq(5)
  end
end

describe Ethon::Curl::LockData do
  it "maps the data types" do
    expect(described_class[:none]).to eq(0)
    expect(described_class[:cookie]).to eq(2)
    expect(described_class[:dns]).to eq(3)
    expect(described_class[:hsts]).to eq(7)
    expect(described_class[:last]).to eq(8)
  end
end

describe "curl share option" do
  it "accepts a share pointer" do
    expect(Ethon::Curl.easy_options(nil)[:share][:type]).to eq(:ffipointer)
  end
end

describe Ethon::Curl::Share do
  let(:share) { described_class.new }

  describe "#share" do
    it "shares a data type" do
      expect { share.share(:cookie) }.not_to raise_error
    end

    it "returns self" do
      expect(share.share(:cookie)).to be(share)
    end

    it "accepts string data types" do
      expect { share.share("dns") }.not_to raise_error
    end

    it "raises on errors" do
      allow(Ethon::Curl).to receive(:share_setopt).and_return(:bad_option)

      expect { share.share(:cookie) }.
        to raise_error(Ethon::Errors::Share, /share option/i)
    end
  end

  describe "#unshare" do
    it "stops sharing a data type" do
      share.share(:cookie)

      expect { share.unshare(:cookie) }.not_to raise_error
    end
  end

  describe "lock callbacks" do
    it "retains the lock and unlock functions" do
      lock = proc { |*| }
      unlock = proc { |*| }

      share.lockfunction = lock
      share.unlockfunction = unlock

      expect(share.lockfunction).to be(lock)
      expect(share.unlockfunction).to be(unlock)
    end

    it "clears the callbacks" do
      share.lockfunction = proc { |*| }
      share.lockfunction = nil

      expect(share.lockfunction).to be_nil
    end

    it "rejects callbacks that are not procs" do
      expect { share.lockfunction = Object.new }.
        to raise_error(Ethon::Errors::InvalidValue)
    end

    it "drops the retained callbacks when the handle is freed" do
      value = described_class.new
      value.lockfunction = proc { |*| }
      address = value.address

      value.free

      expect(described_class.callbacks).not_to have_key(address)
    end

    it "calls the callbacks while sharing cookies" do
      locks = 0
      unlocks = 0
      shared = described_class.new
      shared.lockfunction = proc { |*| locks += 1 }
      shared.unlockfunction = proc { |*| unlocks += 1 }
      shared.share(:cookie)

      first = Ethon::Easy.new
      first.cookiefile = ""
      first.share = shared
      first.cookielist = "example.com\tFALSE\t/\tFALSE\t0\tname\tvalue"

      second = Ethon::Easy.new
      second.cookiefile = ""
      second.share = shared
      second.cookielist

      expect(locks).to be > 0
      expect(unlocks).to be > 0
    end
  end

  describe "#initialize" do
    it "raises when libcurl cannot allocate a handle" do
      allow(Ethon::Curl).to receive(:share_init).and_return(FFI::Pointer::NULL)

      expect { described_class.new }.
        to raise_error(NoMemoryError, "curl_share_init failed")
    end

    it "raises when the share API is unavailable" do
      allow(Ethon::Curl).to receive(:respond_to?).and_call_original
      allow(Ethon::Curl).to receive(:respond_to?).with(:share_init).and_return(false)

      expect { described_class.new }.
        to raise_error(NotImplementedError, /curl_share_init/)
    end
  end
end

describe Ethon::Easy do
  let(:easy) { Ethon::Easy.new }
  let(:share) { Ethon::Curl::Share.new }

  it "retains the share handle" do
    easy.share = share

    expect(easy.share).to be(share)
    expect(easy.instance_variable_get(:@share)).to be(share)
  end

  it "clears the share handle" do
    easy.share = share

    easy.share = nil

    expect(easy.share).to be_nil
  end

  it "clears the share handle on reset" do
    easy.share = share

    easy.reset

    expect(easy.share).to be_nil
  end

  it "shares cookies between easy handles" do
    shared = share.share(:cookie)
    first = Ethon::Easy.new
    first.cookiefile = ""
    first.share = shared
    first.cookielist = "example.com\tFALSE\t/\tFALSE\t0\tname\tvalue"

    second = Ethon::Easy.new
    second.cookiefile = ""
    second.share = shared

    expect(second.cookielist).to include(/name\tvalue/)
  end
end
