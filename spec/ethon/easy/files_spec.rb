require 'spec_helper'

describe Ethon::Easy::Files do
  let!(:easy) { Ethon::Easy.new }

  describe "#open_file" do
    path, mode = '/i/am/no/file', 'w'

    before do
      expect(Ethon::Libc).to receive(:ffi_fopen).with(path, mode)
    end

    it "calls ffi_fopen" do
      easy.open_file(path, mode)
    end

    it "tracks the open files in @open_files" do
      easy.open_file(path, mode)
      expect(easy.instance_variable_get(:@open_files).count).to eq(1)
    end
  end

  describe "#close_all_files" do
    it "calls ffi_fclose on all open files" do
      easy.instance_variable_set(:@open_files, [nil])
      expect(Ethon::Libc).to receive(:ffi_fclose).exactly(1).times
      easy.close_all_files
    end
  end
end
