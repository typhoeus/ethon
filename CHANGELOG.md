# Changelog

## Master

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.12...master)

Bugfixes:

  * URL-encode nullbytes in parameters instead of escaping them to `\\0`.
    ([Tasos Laskos](https://github.com/zapotek)

## 0.5.12

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.11...v0.5.12)

Enhancements:

* Performance optimizations.
  ([Kyle Oppenheim](https://github.com/koppenheim) and [Richie Vos](https://github.com/richievos), [\#48](https://github.com/typhoeus/ethon/pull/48))
* Reuse memory pointer.
  ([Richie Vos](https://github.com/richievos), [\#49](https://github.com/typhoeus/ethon/pull/49))

Bugfixes:

* Fix windows install.
  ([Derik Olsson](https://github.com/derikolsson), [\#47](https://github.com/typhoeus/ethon/pull/47))
* Handle urls that already contain query params.
  ([Turner King](https://github.com/turnerking ), [\#45](https://github.com/typhoeus/ethon/pull/45))

## 0.5.11

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.10...v0.5.11)

Enhancements:

* Add support for postredirs, unrestricted_auth.
* Add support for cookie, cookiejar, cookiefile.
  ([erwanlr](https://github.com/erwanlr), [\#46](https://github.com/typhoeus/ethon/pull/46))
* Relax ffi requirements.
  ([voxik](https://github.com/voxik), [\#40](https://github.com/typhoeus/ethon/pull/40))
* Various documentation improvements.
  ([Craig Little](https://github.com/craiglittle))

Bugfixes:

* Fix the memory leaks.
  ([Richie Vos](https://github.com/richievos), [\#45](https://github.com/typhoeus/ethon/pull/45))

## 0.5.10

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.9...v0.5.10)

Enhancements:

* Allow custom requests.
  ([Nathan Sutton](https://github.com/nate), [\#36](https://github.com/typhoeus/ethon/pull/36))
* Use updated version of FFI.

Bugfixes:

* Fix windows install issue.
  ([brainsucker](https://github.com/brainsucker), [\#38](https://github.com/typhoeus/ethon/pull/38))

## 0.5.9

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.8...v0.5.9)

Enhancements:

* Allow to set multiple protocols.

## 0.5.8

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.7...v0.5.8)

Enhancements:

* Add support for protocols and redir_protocols(
  [libcurl SASL buffer overflow vulnerability](http://curl.haxx.se/docs/adv_20130206.html)).
* Add max_send_speed_large and max_recv_speed_large([Paul Schuegraf](https://github.com/pschuegr), [\#33](https://github.com/typhoeus/ethon/pull/33))

## 0.5.7

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.6...v0.5.7)

Enhancements:

* Use new version of ffi.

## 0.5.6

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.4...v0.5.6)

Bugfixes:

* Easy#reset resets on_complete callbacks.

## 0.5.4

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.3...v0.5.4)

Enhancements:

* Use Libc#getdtablesize to get the FDSet size.
* New libcurl option accept_encoding.
* Documentation updates.

## 0.5.3

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.2...v0.5.3)

Enhancements:

* Deprecate Easy#prepare. It is no longer necessary.
* Unroll metaprogramming for easy and multi options.
* More specs.

Bugfixes:

* Correct size for FDSets
* Add proxytypes to enums.

## 0.5.2

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.1...v0.5.2)

Enhancements:

* New libcurl option keypasswd.

Bugfixes:

* Correct request logging when using multi interface.
* Remove invalid libcurl option sslcertpasswd.

## 0.5.1

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.0...v0.5.1)

Bugfixes:

* Mark Curl.select and Curl.easy_perform as blocking so that the GIL is
  released by ffi.

## 0.5.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.4.4...v0.5.0)

Enhancements:

* New libcurl option proxyuserpwd
* Rename response_header to response_headers

Bugfixes:

* Mark Curl.select and Curl.easy_perform as blocking so that the GIL is
  released by ffi.

## 0.4.4

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.4.3...v0.4.4)

Enhancements:

* Prepare multi explicit like easy

## 0.4.3

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.4.2...v0.4.3)

Enhancements:

* Remove deprecated libcurl option put
* More documentation
* New libcurl option connecttimeout_ms and timeout_ms
* Support multi options

Bugfixes:

* Handle nil values in query params

## 0.4.2

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.4.1...v0.4.2)

Enhancements:

* New libcurl option forbid_reuse
* Use libcurls escape instead of CGI::escape

## 0.4.1

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.4.0...v0.4.1)

Bugfixes:

* Handle nested hash in an array in params correct
  ( [\#201](https://github.com/typhoeus/typhoeus/issues/201) )

## 0.4.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.3.0...v0.4.0)

Enhancements:

* ruby 1.8.7 compatible
* Ethon.logger
* Deal with string param/body
* More documentation

Bugfixes:

* Add multi_cleanup to curl

## 0.3.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.2.0...v0.3.0)

Enhancements:

* New libcurl option proxyport
* Raise invalid value error when providing a wrong key for sslversion or httpauth

Bugfixes:

* Libcurl option sslversion is handled correct

## 0.2.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.1.0...v0.2.0)

Enhancements:

* GET requests are using custom requests only when there is a request body
* Easy#on_complete takes multiple callbacks
* raise Errors::GlobalInit when libcurls global_init failed instead of
  runtime error
* raise Errors::InvalidOption if option is invalid

## 0.1.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.0.2...v0.1.0)

Enhancements:

* Documentation
  ( [Alex P](https://github.com/ifesdjeen), [\#13](https://github.com/typhoeus/ethon/issues/13) )
* New libcurl option dns_cache_timeout
  ( [Chris Heald](https://github.com/cheald), [\#192](https://github.com/typhoeus/typhoeus/pull/192) )

Bugfixes:

* Libcurl option ssl_verifyhost takes an integer.
* Add space between header key and value.

## 0.0.2

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.0.1...v0.0.2)

Bugfixes:

* Add libcurl.so.4 to ffi_lib in order to load correct lib on Debian.
* Escape zero bytes.

## 0.0.1 Initial version
