# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl do
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
  end

  describe ".check_pid!" do
    it "resets process state after a fork when libcurl is not initialized" do
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
end
