# frozen_string_literal: true
require 'webrick'
require 'webrick/httpproxy'
require 'socket'
require 'stringio'
require 'timeout'

# Runs an authenticated HTTP proxy for specs that need to observe proxying.
class LocalProxyServer
  USERNAME = "user"
  PASSWORD = "pass"

  attr_reader :port

  def initialize(port)
    @port = port
    ensure_port_available!
    @server = WEBrick::HTTPProxyServer.new(
      :Port => port,
      :Host => 'localhost',
      :AccessLog => [],
      :Logger => WEBrick::BasicLog.new(StringIO.new),
      :ProxyAuthProc => proc do |request, response|
        WEBrick::HTTPAuth.proxy_basic_auth(request, response, "ethon") do |user, password|
          user == USERNAME && password == PASSWORD
        end
      end
    )
    Thread.new { @server.start }
    wait_until_booted
  end

  private

  def ensure_port_available!
    server = TCPServer.new('127.0.0.1', port)
    server.close
  rescue Errno::EADDRINUSE
    raise "Port #{port} is already in use; another ethon test run may still be active."
  end

  def wait_until_booted
    Timeout.timeout(10) do
      begin
        TCPSocket.new("127.0.0.1", port).close
      rescue Errno::ECONNREFUSED
        sleep(0.005)
        retry
      end
    end
  end
end
