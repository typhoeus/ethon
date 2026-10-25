# frozen_string_literal: true
require 'spec_helper'

module OptionTableSpecHelpers
  # curl_easytype values as returned by curl_easy_option_*.
  CURL_TYPE_COMPATIBILITY = {
    :none => [:long],
    :int => [:long, :values],
    :bool => [:long],
    :time => [:long, :values],
    :enum => [:long, :values],
    :bitmask => [:long, :values],
    :off_t => [:off_t],
    :string => [:string, :object],
    :binary_string => [:string, :object],
    :string_escape_null => [:string, :object],
    :string_as_pointer => [:string, :object],
    :ffipointer => [:object, :cbptr],
    :curl_slist => [:slist],
    :buffer => [:object],
    :cbdata => [:cbptr, :object],
    :callback => [:function, :cbptr],
    :debug_callback => [:function, :cbptr],
    :progress_callback => [:function, :cbptr],
    :xferinfo_callback => [:function, :cbptr],
    :socket_callback => [:function, :cbptr],
    :timer_callback => [:function, :cbptr],
    :blob => [:blob],
    :dontuse_callback => [:function, :cbptr],
    :dontuse_object => [:object, :string]
  }.freeze

  # Historical names libcurl reports as the canonical name for an id.
  NATIVE_NAME_ALIASES = {
    "FILE" => "WRITEDATA",
    "INFILE" => "READDATA",
    "PROGRESSDATA" => "XFERINFODATA",
    "WRITEHEADER" => "HEADERDATA",
    "FTP_RESPONSE_TIMEOUT" => "SERVER_RESPONSE_TIMEOUT",
    # libcurl 7.88 spells this with three Ls.
    "MAIL_RCPT_ALLOWFAILS" => "MAIL_RCPT_ALLLOWFAILS"
  }.freeze

  EASY_ALIASES = {
    :writedata => :file,
    :readdata => :infile,
    :headerdata => :writeheader,
    :encoding => :accept_encoding,
    :post301 => :postredir,
    :ftplistonly => :dirlistonly,
    :ftpappend => :append,
    :server_response_timeout => :ftp_response_timeout,
    :ftp_ssl => :use_ssl,
    :unix_socket => :unix_socket_path,
    :pinned_public_key => :pinnedpublickey,
    :rtspheader => :httpheader,
    :sslcertpasswd => :keypasswd,
    :sslkeypasswd => :keypasswd,
    :krb4level => :krblevel,
    :proxy_sslcertpasswd => :proxy_keypasswd,
    :proxy_sslkeypasswd => :proxy_keypasswd,
    :proxy_pinned_public_key => :proxy_pinnedpublickey
  }.freeze
end

# Cross-checks Ethon's option table against the metadata the loaded libcurl
# exposes. This catches wrong option numbers, wrong native types, and aliases
# that drift apart without having to hard-code every option twice.
describe "Ethon's libcurl option table" do
  let(:options) { Ethon::Curl.easy_options(nil) }

  # Every option id may have several Ruby names. The first name inserted into
  # the table is the one the option was declared with, the rest are aliases.
  let(:option_groups) do
    groups = {}
    options.each do |name, props|
      groups[props[:opt]] ||= [name, props]
    end
    groups
  end

  it "describes every option with a known type and a native id" do
    options.each do |name, props|
      expect(OptionTableSpecHelpers::CURL_TYPE_COMPATIBILITY).to have_key(props[:type]), name.to_s
      expect(props[:opt]).to be_a(Integer), name.to_s
      expect(props[:opt]).to be >= 0, name.to_s
    end
  end

  it "gives every enum and bitmask option a non-empty value map" do
    options.each do |name, props|
      next unless [:enum, :bitmask].include?(props[:type])

      expect(props[:opts]).to be_a(Hash), name.to_s
      expect(props[:opts]).not_to be_empty, name.to_s
    end
  end

  it "gives every buffer option a positive size" do
    options.each do |name, props|
      next unless props[:type] == :buffer

      expect(props[:opts]).to be_a(Integer), name.to_s
      expect(props[:opts]).to be > 0, name.to_s
    end
  end

  it "keeps every alias on the exact same native option" do
    OptionTableSpecHelpers::EASY_ALIASES.each do |alias_name, canonical|
      expect(options).to have_key(canonical), canonical.to_s
      expect(options).to have_key(alias_name), alias_name.to_s
      expect(options[alias_name]).to equal(options[canonical]), alias_name.to_s
    end
  end

  describe "against the loaded libcurl" do
    before do
      skip "curl_easy_option_by_id is unavailable" unless Ethon::Curl.respond_to?(:easy_option_by_id)
    end

    it "maps every option id to the expected canonical CURLOPT name" do
      problems = []

      option_groups.each_value do |name, props|
        info = Ethon::Curl.option_by_id(props[:opt])
        # Options added after the loaded libcurl cannot be described by it.
        next if info.nil?

        expected = name.to_s.upcase
        actual = info.name
        next if actual == expected
        next if OptionTableSpecHelpers::NATIVE_NAME_ALIASES[expected] == actual

        problems << "#{name}: expected #{expected}, got #{actual}"
      end

      expect(problems).to eq([])
    end

    it "declares a native type compatible with every option" do
      problems = []

      option_groups.each_value do |name, props|
        info = Ethon::Curl.option_by_id(props[:opt])
        next if info.nil?

        allowed = OptionTableSpecHelpers::CURL_TYPE_COMPATIBILITY.fetch(props[:type])
        next if allowed.include?(info.type)

        problems << "#{name}: #{props[:type]} cannot be #{info.type}"
      end

      expect(problems).to eq([])
    end

    it "agrees with supports_option? for every option" do
      options.each_key do |name|
        props = options[name]
        expects_support = !Ethon::Curl.option_by_id(props[:opt]).nil?

        expect(Ethon::Curl.supports_option?(name)).to eq(expects_support), name.to_s
      end
    end
  end
end
