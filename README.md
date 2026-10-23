[![Gem Version](https://badge.fury.io/rb/ethon.svg)](https://badge.fury.io/rb/ethon)
[![Build Status](https://github.com/typhoeus/ethon/workflows/Ruby/badge.svg)](https://github.com/typhoeus/ethon/actions/workflows/ruby.yml)

#  Ethon

In Greek mythology, Ethon, the son of Typhoeus and Echidna, is a gigantic eagle. So much for the history.
In the modern world, Ethon is a very basic libcurl wrapper using ffi.

* [Documentation](http://rubydoc.info/github/typhoeus/ethon/frames/Ethon)
* [Website](http://typhoeus.github.com/)
* [Mailing list](http://groups.google.com/group/typhoeus)

## Installation

With bundler:

    gem "ethon"

With rubygems:

    gem install ethon

## Usage

Making the first request is simple:

```ruby
easy = Ethon::Easy.new(url: "www.example.com")
easy.perform
#=> :ok
```

You have access to various options, such as following redirects:

```ruby
easy = Ethon::Easy.new(url: "www.example.com", followlocation: true)
easy.perform
#=> :ok
```

Once you're done you can inspect the response code and body:

```ruby
easy = Ethon::Easy.new(url: "www.example.com", followlocation: true)
easy.perform
easy.response_code
#=> 200
easy.response_body
#=> "<!doctype html><html ..."
```

## Http

In order to make life easier, there are some helpers for making HTTP requests:

```ruby
easy = Ethon::Easy.new
easy.http_request("www.example.com", :get, { params: {a: 1} })
easy.perform
#=> :ok
```

```ruby
easy = Ethon::Easy.new
easy.http_request("www.example.com", :post, { params: { a: 1 }, body: { b: 2 } })
easy.perform
#=> :ok
```

This is really handy when making requests since you don't have to care about setting
everything up correctly.

## Http2
Standard http2 servers require the client to connect once and create a session (multi) and then add simple requests to the multi handler.
The `perform` method then takes all the requests in the multi handler and sends them to the server.

See the following example
```ruby
multi = Ethon::Multi.new
easy = Ethon::Easy.new

easy.http_request("www.example.com/get", :get, { http_version: :httpv2_0 })

# Sending a request with http version 2 will send an Upgrade header to the server, which many older servers will not support
# See below for more info: https://everything.curl.dev/http/http2
# If this is a problem, send the below:
easy.http_request("www.example.com/get", :get, { http_version: :httpv2_prior_knowledge })

# To set the server to use http2 with https and http1 with http, send the following:
easy.http_request("www.example.com/get", :get, { http_version: :httpv2_tls })

multi.add(easy)
multi.perform
```

## Lower-level libcurl APIs

Ethon exposes wrappers for some of libcurl's newer APIs. Functions that are not
available in the loaded libcurl are attached only when supported, and the Ruby
wrappers raise `NotImplementedError` when the feature is missing.

```ruby
# URL API
url = Ethon::Curl::Url.new("https://example.com/a")
url.get(:host) #=> "example.com"
url.set(:path, "/b")
url.to_s       #=> "https://example.com/b"

# MIME API
easy = Ethon::Easy.new(url: "http://example.com/upload")
mime = Ethon::Curl::Mime.new(easy)
part = mime.addpart
part.name = "file"
part.file = "/tmp/example.txt"
part.headers = { "X-Checksum" => "abc123" }
easy.mime = mime

# Share cookies or DNS data between easy handles
share = Ethon::Curl::Share.new.share(:cookie)
easy.share = share

# Structured response headers and option metadata
easy.perform
easy.header("Content-Type")
easy.each_header { |header| puts "#{header.name}: #{header.value}" }
Ethon::Curl.easy_option("URL")
Ethon::Curl.protocols
```

When a share handle is used from more than one thread, set
`Share#lockfunction=` and `Share#unlockfunction=` so libcurl can synchronize
access to the shared data.

## Thread and fork safety

Ethon can be used from multiple threads, but it does not synchronize access to
individual handles. Follow [libcurl's thread-safety rules](https://curl.se/libcurl/c/threadsafe.html):

* Separate `Ethon::Easy` and `Ethon::Multi` instances may run concurrently in
  different threads.
* Do not use the same `Easy` or `Multi` instance from more than one thread at a
  time. This includes changing its options while a transfer is running.
* Callbacks run on the thread performing the transfer. Synchronize any shared
  application state accessed by a callback.
* When using threads, set `nosignal: true` unless your libcurl uses a threaded
  or c-ares resolver. See libcurl's signal guidance for the associated DNS
  timeout and `SIGPIPE` considerations.

With libcurl older than 7.84.0, create an Ethon handle before starting other
application threads so libcurl's global initialization happens while the
process is still single-threaded.

Ethon handles and initialized libcurl state must not be inherited across a
`fork`. If any `Easy` or `Multi` was created before forking, libcurl is already
initialized and the child cannot create new handles either; use `fork` followed
by `exec` in that case. If libcurl was not initialized before forking, create
all `Easy` and `Multi` instances after the fork. Ethon raises
`Ethon::Errors::ForkSafety` when a child process tries to use inherited libcurl
state.

##  LICENSE

(The MIT License)

Copyright © 2012-2016 [Hans Hasselberg](http://www.hans.io)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
