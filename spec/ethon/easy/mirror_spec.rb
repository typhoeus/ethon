# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Easy::Mirror do
  let(:options) { nil }
  let(:mirror) { described_class.new(options) }

  describe "::INFORMATIONS_TO_LOG" do
    [
      :return_code, :response_code, :response_body, :response_headers,
      :total_time, :starttransfer_time, :appconnect_time,
      :pretransfer_time, :connect_time, :namelookup_time, :redirect_time,
      :size_upload, :size_download, :speed_upload, :speed_upload,
      :effective_url, :primary_ip, :redirect_count, :redirect_url, :debug_info,
      :error_message
    ].each do |name|
      it "contains #{name}" do
        expect(described_class::INFORMATIONS_TO_MIRROR).to include(name)
      end
    end
  end

  describe "accessors" do
    let(:options) do
      described_class::INFORMATIONS_TO_MIRROR.each_with_object({}) do |name, hash|
        hash[name] = name.to_s
      end
    end
    let(:mirror) { described_class.new(options) }

    it "reads every information from options" do
      described_class::INFORMATIONS_TO_MIRROR.each do |name|
        expect(mirror.public_send(name)).to eq(name.to_s)
      end
    end
  end

  describe "#to_hash" do
    let(:options) { {:return_code => 1} }

    it "returns mirror as hash" do
      expect(mirror.to_hash).to eq(options)
    end
  end

  describe "#log_informations" do
    let(:options) { {:return_code => 1} }

    it "returns hash" do
      expect(mirror.log_informations).to be_a(Hash)
    end

    it "only calls methods that exist" do
      described_class::INFORMATIONS_TO_LOG.each do |method_name|
        expect(mirror.respond_to? method_name).to eql(true)
      end
    end

    it "includes return code" do
      expect(mirror.log_informations).to include(options)
    end

    context "when the effective URL contains credentials" do
      let(:options) do
        { :effective_url => "https://user:secret@example.com/path", :return_code => :ok }
      end

      it "redacts the userinfo" do
        expect(mirror.log_informations[:effective_url]).
          to eq("https://[REDACTED]@example.com/path")
      end

      it "keeps the rest of the options" do
        expect(mirror.log_informations[:return_code]).to eq(:ok)
      end
    end

    it "leaves URLs without credentials alone" do
      mirror = described_class.new(:effective_url => "https://example.com/a@b")

      expect(mirror.log_informations[:effective_url]).
        to eq("https://example.com/a@b")
    end
  end
end
