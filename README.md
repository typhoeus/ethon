#  Ethon [![Build Status](https://secure.travis-ci.org/typhoeus/ethon.png?branch=master)](http://travis-ci.org/typhoeus/ethon)

In the greek mythology Ethon is a gigantic eagle the son of Typhoeus and Echidna. So much for the history.
In the modern world Ethon is a very basic libcurl wrapper using ffi.

* [Documentation](http://rubydoc.info/github/typhoeus/ethon)

## Caution

This is __alpha__!

## Installation

With bundler:

    gem "ethon", :git => "https://github.com/typhoeus/ethon.git", :branch => "master"

## Usage

Making the first request is realy simple:

```ruby
easy = Ethon::Easy.new(:url => "www.google.de")
easy.prepare
easy.perform
#=> :ok
```

You have access to various options like following redirects:

```ruby
easy = Ethon::Easy.new(:url => "www.google.com", :follow_location => true)
easy.prepare
easy.perform
#=> :ok
```
Once you're done you can look at the response code and body:

```ruby
easy = Ethon::Easy.new(:url => "www.google.de")
easy.prepare
easy.perform
easy.response_code
#=> 200
easy.response_body
#=> "<!doctype html><html ..."
```

## Http

In order to make life easier there are some helpers for doing http requests:

```ruby
easy = Ethon::Easy.new
easy.http_request("www.google.de", :get, { :params => {:a => 1} })
easy.prepare
easy.perform
#=> :ok

easy = Ethon::Easy.new
easy.http_request("www.google.de", :post, { :params => { :a => 1 }, :body => { :b => 2 } })
easy.prepare
easy.perform
#=> :ok
```

This really handy when doing requests since you don't have to care about setting
everything up correct.

##  LICENSE

(The MIT License)

Copyright © 2012 [Hans Hasselberg](http://www.hans.io)

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
