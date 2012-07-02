# Changelog

## Master

[Full Changelog](http://github.com/typhoeus/ethon/compare/v0.2.0...master)

Enhancements:

* New libcurl options proxyport

## 0.2.0

[Full Changelog](http://github.com/typhoeus/ethon/compare/v0.1.0...v0.2.0)

Enhancements:

* GET requests are using custom requests only when there is a request body
* Easy#on_complete takes multiple callbacks
* raise Errors::GlobalInit when libcurls global_init failed instead of
  runtime error
* raise Errors::InvalidOption if option is invalid

## 0.1.0

[Full Changelog](http://github.com/typhoeus/ethon/compare/v0.0.2...v0.1.0)

Enhancements:

* Documentation
  ( [Alex P](https://github.com/ifesdjeen), [\#13](https://github.com/typhoeus/ethon/issues/13) )
* New libcurl option dns_cache_timeout
  ( [Chris Heald](https://github.com/cheald), [\#192](https://github.com/typhoeus/typhoeus/pull/192) )

Bugfixes:

* Libcurl option ssl_verifyhost takes an integer.
* Add space between header key and value.

## 0.0.2

[Full Changelog](http://github.com/typhoeus/ethon/compare/v0.0.1...v0.0.2)

Bugfixes:

* Add libcurl.so.4 to ffi_lib in order to load correct lib on Debian.
* Escape zero bytes.

## 0.0.1 Initial version
