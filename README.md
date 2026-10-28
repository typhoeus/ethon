[![Gem Version](https://badge.fury.io/rb/ethon.svg)](https://badge.fury.io/rb/ethon)
[![Build Status](https://github.com/typhoeus/ethon/workflows/Ruby/badge.svg)](https://github.com/typhoeus/ethon/actions/workflows/ruby.yml)

# Ethon

Ethon is a lightweight Ruby wrapper around [libcurl](https://curl.se/libcurl/),
built with [FFI](https://github.com/ffi/ffi). It exposes:

- `Ethon::Easy` for a single transfer.
- `Ethon::Multi` for concurrent transfers.
- libcurl options, callbacks, response streaming, debug output, and optional
  lower-level URL, MIME, share, and header APIs.

The name comes from Greek mythology: Ethon was a gigantic eagle and the son of
Typhoeus and Echidna.

* [API documentation](https://rubydoc.info/github/typhoeus/ethon)
* [Changelog](https://github.com/typhoeus/ethon/blob/master/CHANGELOG.md)

## Installation

Add the gem to your bundle:

```sh
bundle add ethon
```

Or install it directly:

```sh
gem install ethon
```

Ethon requires Ruby 2.6 or newer and a libcurl shared library. Install libcurl
with your system package manager, or point `ETHON_CURL_LIBS` at a specific
build (see [Older libcurl versions](#older-libcurl-versions)).

## Usage

Create an `Easy` handle for a single transfer. The constructor accepts libcurl
options such as `followlocation`:

```ruby
easy = Ethon::Easy.new(url: "www.example.com", followlocation: true)
easy.perform
#=> :ok
```

After `perform` returns, read the response:

```ruby
easy.response_code
#=> 200
easy.response_body
#=> "<!doctype html><html ..."
```

## HTTP helpers

`http_request` configures the URL, method, query parameters, and body:

```ruby
easy = Ethon::Easy.new
easy.http_request("www.example.com", :get, { params: { a: 1 } })
easy.perform
#=> :ok
```

```ruby
easy = Ethon::Easy.new
easy.http_request("www.example.com", :post, { params: { a: 1 }, body: { b: 2 } })
easy.perform
#=> :ok
```

File values in a `:body` hash are sent as `multipart/form-data`. Ethon loads
the optional `mime-types` gem on the first upload to detect each part's content
type; without it, parts use `application/octet-stream`.

## Parallel requests

Add `Easy` handles to a `Multi` and call `perform`:

```ruby
multi = Ethon::Multi.new
2.times do
  easy = Ethon::Easy.new(url: "www.example.com")
  multi.add(easy)
end
multi.perform
```

## HTTP/2

Use `:http_version` to request HTTP/2. `:httpv2_tls` negotiates HTTP/2 over
TLS and uses HTTP/1.1 for plain HTTP. `:httpv2_0` also attempts the HTTP/2
Upgrade handshake on plain HTTP, which many older servers do not support.
`:httpv2_prior_knowledge` starts HTTP/2 without negotiation. See the
[libcurl HTTP/2 documentation](https://everything.curl.dev/http/versions/http2.html)
for details.

HTTP/2 works with a single easy handle. A multi handle lets several requests
share the connection and multiplex them:

```ruby
multi = Ethon::Multi.new
easy = Ethon::Easy.new

easy.http_request(
  "https://www.example.com/get",
  :get,
  { http_version: :httpv2_tls }
)

multi.add(easy)
multi.perform
```

## Lower-level libcurl APIs

Ethon exposes wrappers for some of libcurl's newer APIs. Optional bindings are
attached only when the loaded libcurl exports them. Wrappers for the URL, MIME,
share, header, and transfer helpers raise `NotImplementedError` when the
underlying function is missing; introspection helpers return `nil` or `[]`.

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

## Older libcurl versions

Ethon attaches some functions only when the loaded libcurl exports them.
Wrappers that check for a missing function raise `NotImplementedError`; the
introspection helpers return `nil` or `[]`. This keeps the gem loadable with
libcurl versions that predate the URL, MIME, share, or structured-header APIs.

libcurl silently ignores unknown options, which can make a request run with a
different configuration than intended. Ethon therefore raises
`Ethon::Errors::UnsupportedOption` when `curl_easy_setopt` reports
`CURLE_UNKNOWN_OPTION`, and `Ethon::Errors::SetOption` for other rejected
values. Guard optional settings when supporting older runtimes:

```ruby
easy.tcp_keepcnt = 30 if Ethon::Curl.supports_option?(:tcp_keepcnt)
easy.httpsig_key = key if Ethon::Curl.version_at_least?("8.23.0")
```

`Curl.supports_option?` asks libcurl's own option table on 7.73.0 and newer.
Older versions cannot answer that question, so it returns `true` for every
option Ethon knows; setting an unsupported option still raises. Multi options
are only checked against Ethon's table, because libcurl does not expose their
metadata.

The deprecated form API is attached only when the loaded libcurl exports it,
because libcurl can be built with `--disable-form-api`. Multipart bodies use the
MIME API when available and fall back to the form API otherwise.

Point `ETHON_CURL_LIBS` at a specific libcurl build to test against it:

```sh
ETHON_CURL_LIBS=/opt/curl/lib/libcurl.so bundle exec rake
```

CI builds libcurl 7.88 in addition to the system package and 8.23 to catch
accidental use of newer symbols and options. The 8.23 build uses
`--disable-form-api`, so the missing form API path is exercised too.

## Debugging

Set `verbose: true` on an `Easy` to collect libcurl's debug messages.
`Easy#debug_info` returns a `DebugInfo` object; use `#to_a` for every message
or `#to_h` to group them by type (such as `:text`, `:header_in`, and
`:header_out`). `Easy#debugfunction` registers an observer. The messages are
also written through `Ethon.logger` at the debug level, so configure it to see
them:

```ruby
Ethon.logger.level = Logger::DEBUG
```

Response body data is not written to the log; it stays available through
`Easy#debug_info` and the `debugfunction` observer.

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

## License

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
