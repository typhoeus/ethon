# frozen_string_literal: true
require 'spec_helper'
require 'socket'

describe Ethon::Easy do
  describe "#postfields=" do
    let(:easy) { Ethon::Easy.new }

    # libcurl treats an indeterminate body size as a chunked upload and reads
    # the body from the default read callback, which is stdin. Reading stdin
    # blocks whenever it is a terminal or a pipe that stays open, so assert on
    # what goes over the wire instead.
    def capture_request_head(easy)
      server = TCPServer.new("127.0.0.1", 0)
      head = nil
      server_thread = Thread.new do
        client = server.accept
        head = +""
        head << client.readpartial(1) until head.end_with?("\r\n\r\n")
        client.write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
        client.close
      end

      easy.url = "http://127.0.0.1:#{server.addr[1]}/echo"
      yield easy
      easy.perform

      server_thread.join(5)
      full = head
      [full, server]
    ensure
      server.close if server && !server.closed?
    end

    it "clears the copied body size" do
      head, = capture_request_head(easy) do |e|
        e.copypostfields = "abc"
        e.copypostfields = nil
      end

      expect(head).to start_with("POST /echo HTTP/1.1\r\n")
      expect(head).to include("Content-Length: 0\r\n")
      expect(head).not_to include("Transfer-Encoding")
    end

    it "clears the post body size" do
      head, = capture_request_head(easy) do |e|
        e.postfields = "abc"
        e.postfields = nil
      end

      expect(head).not_to include("Transfer-Encoding")
    end
  end
end
