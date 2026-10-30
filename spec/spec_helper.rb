# frozen_string_literal: true
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'bundler'
require 'fileutils'
require 'tmpdir'
Bundler.setup
require "ethon"
require 'rspec'

require_relative 'support/localhost_server'
require_relative 'support/server'
require_relative 'support/tls_certificate'

# TLS server used by specs that need real certificate information.
TEST_HTTPS_PORT = 3443
TEST_TLS_DIR = Dir.mktmpdir("ethon-tls")
TEST_TLS_DIR_PID = Process.pid
# Specs fork, and a forked child would otherwise clean up the parent's files.
at_exit { FileUtils.remove_entry(TEST_TLS_DIR) if Process.pid == TEST_TLS_DIR_PID }

TEST_TLS_CERTIFICATE, TEST_TLS_KEY = TLSCertificate.generate("localhost")
TEST_TLS_CA_FILE = File.join(TEST_TLS_DIR, "server-ca.pem")
File.write(TEST_TLS_CA_FILE, TEST_TLS_CERTIFICATE.to_pem)

TEST_TLS_OTHER_CA_FILE = File.join(TEST_TLS_DIR, "other-ca.pem")
other_ca, = TLSCertificate.generate("other")
File.write(TEST_TLS_OTHER_CA_FILE, other_ca.to_pem)

# Ethon.logger = Logger.new($stdout).tap do |log|
#   log.level = Logger::DEBUG
# end

module EthonSpecHelpers
  def skip_on_windows(reason = "not supported on Windows")
    skip reason if Gem.win_platform?
  end
end

RSpec.configure do |config|
  config.include EthonSpecHelpers
  config.order = :random

  config.before(:suite) do
    # Initialize libcurl before any example can install a logger expectation;
    # otherwise the one-time init debug message depends on example order.
    Ethon::Curl.init
    LocalhostServer.new(TESTSERVER.new, 3001)
    LocalhostServer.new(
      TESTSERVER.new,
      TEST_HTTPS_PORT,
      :SSLEnable => true,
      :SSLCertificate => TEST_TLS_CERTIFICATE,
      :SSLPrivateKey => TEST_TLS_KEY
    )
  end
end
