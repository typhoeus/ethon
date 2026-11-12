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

    it "raises after a fork when libcurl is initialized and the child has not opted in" do
      skip_on_windows "fork is not supported on Windows"
      Ethon::Curl.init
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          results = [proc { Ethon::Easy.new }, proc { Ethon::Multi.new }].map do |operation|
            begin
              operation.call
              "ok"
            rescue Ethon::Errors::ForkSafety => e
              e.message
            end
          end
          writer.write(Marshal.dump(results))
        rescue Exception => e
          writer.write(Marshal.dump(["#{e.class}: #{e.message}"]))
        ensure
          writer.close
        end
      end
      writer.close

      expect(Marshal.load(reader.read)).to eq([Ethon::Errors::ForkSafety.new.message] * 2)
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end
  end

  describe ".allow_handles_after_fork!" do
    it "lets a child create new handles on libcurl initialized before the fork" do
      skip_on_windows "fork is not supported on Windows"
      skip_on_macos "allow_handles_after_fork! is not supported on macOS"
      Ethon::Curl.init
      expect(Ethon::Curl).not_to receive(:global_init)
      expect(Ethon::Curl).not_to receive(:global_cleanup)
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Curl.allow_handles_after_fork!
          Ethon::Easy.new.handle
          Ethon::Multi.new.handle
          writer.write("ok")
        rescue Exception => e
          writer.write("#{e.class}: #{e.message}")
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("ok")
      Process.wait(pid)
      pid = nil
      expect($?).to be_success
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "lets a child perform a request after opting in" do
      skip_on_windows "fork is not supported on Windows"
      skip_on_macos "allow_handles_after_fork! is not supported on macOS"
      Ethon::Curl.init
      expect(Ethon::Curl).not_to receive(:global_init)
      expect(Ethon::Curl).not_to receive(:global_cleanup)
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Curl.allow_handles_after_fork!
          easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
          writer.write("#{easy.perform} #{easy.response_code}")
        rescue Exception => e
          writer.write("#{e.class}: #{e.message}")
        ensure
          writer.close
        end
      end
      writer.close

      expect(IO.select([reader], nil, nil, 30)).not_to be_nil
      expect(reader.read).to eq("ok 200")
      Process.wait(pid)
      pid = nil
      expect($?).to be_success
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      if pid && !Process.waitpid(pid, Process::WNOHANG)
        Process.kill(:KILL, pid)
        Process.wait(pid)
      end
    end

    it "lets a child perform a request through a Multi after opting in" do
      skip_on_windows "fork is not supported on Windows"
      skip_on_macos "allow_handles_after_fork! is not supported on macOS"
      Ethon::Curl.init
      expect(Ethon::Curl).not_to receive(:global_init)
      expect(Ethon::Curl).not_to receive(:global_cleanup)
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Curl.allow_handles_after_fork!
          easy = Ethon::Easy.new(:url => "http://127.0.0.1:3001/")
          multi = Ethon::Multi.new
          multi.add(easy)
          multi.perform
          writer.write("#{easy.return_code} #{easy.response_code}")
        rescue Exception => e
          writer.write("#{e.class}: #{e.message}")
        ensure
          writer.close
        end
      end
      writer.close

      expect(IO.select([reader], nil, nil, 30)).not_to be_nil
      expect(reader.read).to eq("ok 200")
      Process.wait(pid)
      pid = nil
      expect($?).to be_success
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      if pid && !Process.waitpid(pid, Process::WNOHANG)
        Process.kill(:KILL, pid)
        Process.wait(pid)
      end
    end

    it "does nothing when the child calls it again" do
      skip_on_windows "fork is not supported on Windows"
      skip_on_macos "allow_handles_after_fork! is not supported on macOS"
      Ethon::Curl.init
      parent_mutex = Ethon::Curl.class_variable_get(:@@curl_mutex)
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Curl.allow_handles_after_fork!
          mutex = Ethon::Curl.class_variable_get(:@@curl_mutex)
          Ethon::Curl.allow_handles_after_fork!
          Ethon::Easy.new.handle
          writer.write([
            mutex.equal?(parent_mutex) ? "parent mutex" : "new mutex",
            Ethon::Curl.class_variable_get(:@@curl_mutex).equal?(mutex) ? "kept" : "replaced"
          ].join(", "))
        rescue Exception => e
          writer.write("#{e.class}: #{e.message}")
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("new mutex, kept")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "applies only to the process that calls it" do
      skip_on_windows "fork is not supported on Windows"
      skip_on_macos "allow_handles_after_fork! is not supported on macOS"
      Ethon::Curl.init
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Curl.allow_handles_after_fork!
          Ethon::Easy.new
          grandchild = fork do
            begin
              Ethon::Easy.new
              writer.write("ok")
            rescue Exception => e
              writer.write(e.class.name)
            ensure
              writer.close
            end
          end
          Process.wait(grandchild)
        rescue Exception => e
          writer.write("#{e.class}: #{e.message}")
        ensure
          writer.close
        end
      end
      writer.close

      expect(reader.read).to eq("Ethon::Errors::ForkSafety")
      Process.wait(pid)
      pid = nil
    ensure
      reader.close if reader && !reader.closed?
      writer.close if writer && !writer.closed?
      Process.wait(pid) if pid
    end

    it "lets a process forked from a child that opted in opt in again" do
      skip_on_windows "fork is not supported on Windows"
      skip_on_macos "allow_handles_after_fork! is not supported on macOS"
      Ethon::Curl.init
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        begin
          Ethon::Curl.allow_handles_after_fork!
          Ethon::Easy.new
          grandchild = fork do
            begin
              Ethon::Curl.allow_handles_after_fork!
              Ethon::Easy.new
              writer.write("ok")
            rescue Exception => e
              writer.write(e.class.name)
            ensure
              writer.close
            end
          end
          Process.wait(grandchild)
        rescue Exception => e
          writer.write("#{e.class}: #{e.message}")
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

    it "does not change the process that initialized libcurl" do
      Ethon::Curl.init
      mutex = Ethon::Curl.class_variable_get(:@@curl_mutex)
      expect(Ethon::Curl).not_to receive(:global_init)
      expect(Ethon::Curl).not_to receive(:global_cleanup)

      Ethon::Curl.allow_handles_after_fork!

      expect(Ethon::Curl.class_variable_get(:@@curl_mutex)).to be(mutex)
      expect(Ethon::Easy.new(:url => "http://127.0.0.1:3001/").perform).to eq(:ok)
    end

    context "when the child cleans up" do
      # Stub the platform check so the opt-in succeeds on macOS too. These
      # examples create no handles in the child, and the stubbed libcurl
      # calls below keep it from touching libcurl's global state.
      before { allow(Ethon::Curl).to receive(:macos?).and_return(false) }

      it "raises when the parent initialized libcurl and leaves it initialized" do
        skip_on_windows "fork is not supported on Windows"
        Ethon::Curl.init
        expect(Ethon::Curl).not_to receive(:global_init)
        expect(Ethon::Curl).not_to receive(:global_cleanup)
        reader, writer = IO.pipe
        pid = fork do
          reader.close
          begin
            Ethon::Curl.allow_handles_after_fork!
            error = begin
              Ethon::Curl.cleanup
              nil
            rescue Ethon::Errors::ForkSafety => e
              e.message
            end
            writer.write(Marshal.dump(
              :error => error,
              :initialized => Ethon::Curl.class_variable_get(:@@initialized)
            ))
          rescue Exception => e
            writer.write(Marshal.dump(:error => "#{e.class}: #{e.message}"))
          ensure
            writer.close
          end
        end
        writer.close

        result = Marshal.load(reader.read)
        Process.wait(pid)
        pid = nil

        expect(result).to eq(
          :error => "Ethon cannot clean up libcurl initialized before a fork; " \
            "clean it up in the process that initialized it",
          :initialized => true
        )
      ensure
        reader.close if reader && !reader.closed?
        writer.close if writer && !writer.closed?
        Process.wait(pid) if pid
      end

      it "cleans up libcurl the child initialized itself" do
        skip_on_windows "fork is not supported on Windows"
        Ethon::Curl.send(:class_variable_set, :@@initialized, false)
        calls = []
        allow(Ethon::Curl).to receive(:global_init) { calls << :global_init; 0 }
        allow(Ethon::Curl).to receive(:global_cleanup) { calls << :global_cleanup }
        reader, writer = IO.pipe
        pid = fork do
          reader.close
          begin
            Ethon::Curl.allow_handles_after_fork!
            Ethon::Curl.init
            Ethon::Curl.cleanup
            writer.write(Marshal.dump(calls))
          rescue Exception => e
            writer.write(Marshal.dump(["#{e.class}: #{e.message}"]))
          ensure
            writer.close
          end
        end
        writer.close

        result = Marshal.load(reader.read)
        Process.wait(pid)
        pid = nil

        expect(result).to eq([:global_init, :global_cleanup])
      ensure
        reader.close if reader && !reader.closed?
        writer.close if writer && !writer.closed?
        Process.wait(pid) if pid
      end
    end

    context "on macOS" do
      before { allow(Ethon::Curl).to receive(:macos?).and_return(true) }

      it "raises in a child whose parent initialized libcurl and leaves its state alone" do
        skip_on_windows "fork is not supported on Windows"
        Ethon::Curl.init
        mutex = Ethon::Curl.class_variable_get(:@@curl_mutex)
        reader, writer = IO.pipe
        pid = fork do
          reader.close
          begin
            error = begin
              Ethon::Curl.allow_handles_after_fork!
              nil
            rescue Ethon::Errors::ForkSafety => e
              e.message
            end
            writer.write(Marshal.dump(
              :error => error,
              :loaded_pid => Ethon::Curl.class_variable_get(:@@loaded_pid),
              :same_mutex => Ethon::Curl.class_variable_get(:@@curl_mutex).equal?(mutex)
            ))
          rescue Exception => e
            writer.write(Marshal.dump(:error => "#{e.class}: #{e.message}"))
          ensure
            writer.close
          end
        end
        writer.close

        result = Marshal.load(reader.read)
        Process.wait(pid)
        pid = nil

        expect(result[:error]).to eq("Ethon cannot use libcurl inherited across a fork on macOS; use fork+exec")
        expect(result[:loaded_pid]).to eq(Process.pid)
        expect(result[:same_mutex]).to be(true)
      ensure
        reader.close if reader && !reader.closed?
        writer.close if writer && !writer.closed?
        Process.wait(pid) if pid
      end

      it "sets up a child as check_pid! does when libcurl was not initialized before the fork" do
        skip_on_windows "fork is not supported on Windows"
        Ethon::Curl.send(:class_variable_set, :@@initialized, false)
        mutex = Ethon::Curl.class_variable_get(:@@curl_mutex)
        reader, writer = IO.pipe
        pid = fork do
          reader.close
          begin
            Ethon::Curl.allow_handles_after_fork!
            writer.write(Marshal.dump(
              :loaded_pid => Ethon::Curl.class_variable_get(:@@loaded_pid),
              :same_mutex => Ethon::Curl.class_variable_get(:@@curl_mutex).equal?(mutex)
            ))
          rescue Exception => e
            writer.write(Marshal.dump(:error => "#{e.class}: #{e.message}"))
          ensure
            writer.close
          end
        end
        writer.close

        result = Marshal.load(reader.read)
        child_pid = pid
        Process.wait(pid)
        pid = nil

        expect(result).to eq(:loaded_pid => child_pid, :same_mutex => false)
      ensure
        reader.close if reader && !reader.closed?
        writer.close if writer && !writer.closed?
        Process.wait(pid) if pid
      end

      it "does not change the process that initialized libcurl" do
        Ethon::Curl.init
        mutex = Ethon::Curl.class_variable_get(:@@curl_mutex)

        Ethon::Curl.allow_handles_after_fork!

        expect(Ethon::Curl.class_variable_get(:@@curl_mutex)).to be(mutex)
        expect(Ethon::Easy.new(:url => "http://127.0.0.1:3001/").perform).to eq(:ok)
      end
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
