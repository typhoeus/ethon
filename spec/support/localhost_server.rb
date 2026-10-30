# frozen_string_literal: true
require 'rack'
require 'webrick'
require 'net/http'
require 'openssl'
require 'rackup' if Gem.ruby_version >= Gem::Version.new("3.0.0")
require 'timeout'

# The code for this is inspired by Capybara's server:
#   http://github.com/jnicklas/capybara/blob/0.3.9/lib/capybara/server.rb
class LocalhostServer
  READY_MESSAGE = "Server ready"

  # Fallback to older Rack handler if rackup is not available
  RACKUP_HANDLER =
    if defined?(Rackup::Handler)
      Rackup::Handler::WEBrick
    else
      Rack::Handler::WEBrick
    end

  class Identify
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] == "/__identify__"
        [200, {}, [LocalhostServer::READY_MESSAGE]]
      else
        @app.call(env)
      end
    end
  end

  attr_reader :port

  def initialize(rack_app, port = nil, options = {})
    @port = port || find_available_port
    ensure_port_available! unless port.nil?
    @rack_app = rack_app
    @options = options
    concurrently { boot }
    wait_until(10, "Boot failed.") { booted? }
  end

  private

  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end

  def ensure_port_available!
    server = TCPServer.new('127.0.0.1', port)
    server.close
  rescue Errno::EADDRINUSE
    raise "Port #{port} is already in use; another ethon test run may still be active."
  end

  def boot
    # The suite makes many requests without cleaning up easy handles, so every
    # client connection can stay idle in WEBrick's keep-alive state. With the
    # default MaxClients (100) and RequestTimeout (30) the server eventually
    # stops accepting connections until an idle one times out. Close idle
    # connections quickly and leave plenty of room for concurrent tests.
    server_options = {
      :Port => port,
      :Host => 'localhost',
      :MaxClients => 1000,
      :RequestTimeout => 5
    }.merge(@options)
    # Use WEBrick for tests since it supports all HTTP methods including custom ones like PURGE
    # Puma is stricter about HTTP methods and rejects custom methods with 501 "method not supported"
    app = Identify.new(@rack_app)

    server_options.merge!(:AccessLog => [], :Logger => WEBrick::BasicLog.new(StringIO.new)) unless ENV['VERBOSE_SERVER']

    RACKUP_HANDLER.run(app, **server_options)
  end

  def booted?
    http = ::Net::HTTP.new("127.0.0.1", port)
    if @options[:SSLEnable]
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    res = http.start { |client| client.get('/__identify__') }
    if res.is_a?(::Net::HTTPSuccess) or res.is_a?(::Net::HTTPRedirection)
      return res.body == READY_MESSAGE
    end
  rescue Errno::ECONNREFUSED, Errno::EBADF
    return false
  end

  def concurrently
    if should_use_subprocess?
      pid = Process.fork do
        trap(:INT) { RACKUP_HANDLER.shutdown }
        yield
        exit # manually exit; otherwise this sub-process will re-run the specs that haven't run yet.
      end

      at_exit do
        Process.kill('INT', pid)
        begin
          Process.wait(pid)
        rescue Errno::ECHILD
          # ignore this error...I think it means the child process has already exited.
        end
      end
    else
      @boot_thread = Thread.new do
        begin
          yield
        rescue Exception => e
          @boot_error = e
        end
      end
    end
  end

  def should_use_subprocess?
    # !ENV['THREADED']
    false
  end

  def wait_until(timeout, error_message, &block)
    start_time = Time.now

    while true
      raise @boot_error if @boot_error
      return if yield
      raise Timeout::Error.new(error_message) if (Time.now - start_time) > timeout
      sleep(0.005)
    end
  end
end

