# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl do
  around do |example|
    initialized = Ethon::Curl.class_variable_get(:@@initialized)
    example.run
  ensure
    Ethon::Curl.class_variable_set(:@@initialized, initialized)
  end

  describe ".version_info" do
    it "requests the current version info structure" do
      version_info = instance_double(Ethon::Curl::VersionInfoData)
      expect(Ethon::Curl).to receive(:curl_version_info).with(Ethon::Curl::VERSION_NOW).and_return(version_info)

      expect(Ethon::Curl.version_info).to be(version_info)
    end

    it "uses the native enum size for curl_version" do
      expect(Ethon::Curl::VersionInfoData.members.first).to eq(:curl_version)
      expect(Ethon::Curl::VersionInfoData.offset_of(:version)).to eq(FFI.type_size(:pointer))
    end
  end

  describe ".init" do
    before { Ethon::Curl.send(:class_variable_set, :@@initialized, false) }

    context "when global_init fails" do
      it "raises global init error" do
        expect(Ethon::Curl).to receive(:global_init).and_return(1)
        expect{ Ethon::Curl.init }.to raise_error(Ethon::Errors::GlobalInit)
      end
    end

    context "when global_init works" do
      before { expect(Ethon::Curl).to receive(:global_init).and_return(0) }

      it "doesn't raises global init error" do
        expect{ Ethon::Curl.init }.to_not raise_error
      end

      it "logs" do
        expect(Ethon.logger).to receive(:debug)
        Ethon::Curl.init
      end
    end

    context "when global_cleanup is called" do
      before { expect(Ethon::Curl).to receive(:global_cleanup) }

      it "logs" do
        expect(Ethon.logger).to receive(:debug).twice
        Ethon::Curl.init
        Ethon::Curl.cleanup
      end
    end

    context "when already initialized" do
      before { Ethon::Curl.send(:class_variable_set, :@@initialized, true) }

      it "does not initialize libcurl again" do
        expect(Ethon::Curl).not_to receive(:global_init)

        Ethon::Curl.init
      end

      it "does not clean up when initialization never happened" do
        Ethon::Curl.send(:class_variable_set, :@@initialized, false)
        expect(Ethon::Curl).not_to receive(:global_cleanup)

        Ethon::Curl.cleanup
      end
    end
  end

  describe ".check_pid!" do
    it "resets process state after a fork when libcurl is not initialized" do
      skip_on_windows "fork is not supported on Windows"
      Ethon::Curl.send(:class_variable_set, :@@initialized, false)
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Curl.check_pid!
          writer.write("ok")
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("ok")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end
  end

  describe ".get_info_slist" do
    it "copies and frees caller-owned slists" do
      node = FFI::MemoryPointer.new(Ethon::Curl::SlistNode)
      data = FFI::MemoryPointer.from_string("value")
      struct = Ethon::Curl::SlistNode.new(node)
      struct[:data] = data
      struct[:next] = nil
      result = FFI::MemoryPointer.new(:pointer)
      result.write_pointer(node)
      allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)
      expect(Ethon::Curl).to receive(:slist_free_all).with(node)

      expect(Ethon::Curl.get_info_slist(:cookielist, FFI::Pointer::NULL)).to eq(["value"])
    end

    it "returns nil without freeing when getinfo fails" do
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:unknown_option)
      expect(Ethon::Curl).not_to receive(:slist_free_all)

      expect(Ethon::Curl.get_info_slist(:cookielist, FFI::Pointer::NULL)).to be_nil
    end
  end

  describe ".get_info_certinfo" do
    it "copies libcurl-owned certificate lists without freeing them" do
      node = FFI::MemoryPointer.new(Ethon::Curl::SlistNode)
      data = FFI::MemoryPointer.from_string("Subject:test")
      slist = Ethon::Curl::SlistNode.new(node)
      slist[:data] = data
      slist[:next] = nil
      lists = FFI::MemoryPointer.new(:pointer)
      lists.write_pointer(node)
      certinfo = FFI::MemoryPointer.new(Ethon::Curl::Certinfo)
      struct = Ethon::Curl::Certinfo.new(certinfo)
      struct[:num_of_certs] = 1
      struct[:certinfo] = lists
      result = FFI::MemoryPointer.new(:pointer)
      result.write_pointer(certinfo)
      allow(FFI::MemoryPointer).to receive(:new).with(:pointer).and_return(result)
      allow(Ethon::Curl).to receive(:easy_getinfo).and_return(:ok)
      expect(Ethon::Curl).not_to receive(:slist_free_all)

      expect(Ethon::Curl.get_info_certinfo(:certinfo, FFI::Pointer::NULL)).to eq([["Subject:test"]])
    end
  end
end
