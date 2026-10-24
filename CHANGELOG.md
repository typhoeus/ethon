# Changelog

## Master

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.19.0...master)

### Behavior changes

* `require 'ethon'` no longer loads mime-types: the registry is loaded on the
  first file upload instead, saving about 2.4 MB and 100 ms per process. Code
  relying on ethon to load `MIME::Types` must now require it itself.
  ([Clément Joubert](https://github.com/czj))
* Errors from `curl_easy_setopt` and `curl_multi_setopt` are no longer ignored.
  An option the loaded libcurl does not know raises
  `Ethon::Errors::UnsupportedOption`, and other rejected values raise
  `Ethon::Errors::SetOption`. Setting an option such as
  `Easy#http_version = :httpv3` on a libcurl built without HTTP/3 now raises
  instead of silently running with a different configuration.
  `Curl.supports_option?` and `Curl.version_at_least?` can be used to guard
  optional settings.
  ([#343](https://github.com/typhoeus/ethon/pull/343))

### New libcurl bindings

* Added a URL API wrapper (`Ethon::Curl::Url`) with `get`, `set`, `dup`, and
  `to_s`, plus the `CURLU_*` part, code, and flag enums.
  ([#311](https://github.com/typhoeus/ethon/pull/311))
* Added a MIME API wrapper (`Ethon::Curl::Mime`, `Ethon::Curl::MimePart`) and
  `Easy#mime=`/`#mimepost=` for multipart bodies, including per-part headers.
  ([#312](https://github.com/typhoeus/ethon/pull/312))
* Added a share API wrapper (`Ethon::Curl::Share`) with `Easy#share=` and
  lock/unlock callbacks for multi-threaded sharing.
  ([#313](https://github.com/typhoeus/ethon/pull/313))
* Added structured response headers (`Easy#header`, `Easy#each_header`,
  `Easy#headers_list`), option introspection (`Curl.easy_option`,
  `Curl.option_by_id`, `Curl.each_easy_option`), and version introspection
  (`Curl.protocols`, `Curl.feature_names`, `Curl.version_info_full`).
  ([#314](https://github.com/typhoeus/ethon/pull/314))
* Added `Easy#unescape`, `Easy#pause`, `Easy#upkeep`, `Multi#wait`,
  `Multi#poll`, and `Multi#wakeup`.
  ([#310](https://github.com/typhoeus/ethon/pull/310))
* Added `Multi#assign`, `Multi#native_handles`, the `Curl::SslBackend` enum,
  and optional `curl_global_sslset`/`curl_global_trace` bindings.
  ([#315](https://github.com/typhoeus/ethon/pull/315))

Functions that are not exported by the loaded libcurl are attached
conditionally. Wrappers raise `NotImplementedError` when the function they need
is unavailable; introspection helpers return `nil` or an empty array.

### Fixes and hardening

* `:none` options no longer interpret `false` as enabled, `Ethon.logger = nil`
  falls back to the default logger, and `ETHON_FD_SIZE` is validated and
  rounded up to the native fd_set word size.
* HTTP helper actions are resolved through an explicit class map, so custom
  verbs that collide with `Ethon::Easy::Http` constants such as `:custom` or
  `:actionable` are sent as custom requests instead of raising.
* The `select` fallback in `Multi#set_fds` now sleeps for the libcurl timeout
  when no file descriptors are ready instead of busy-waiting in 1ms steps.
* `Easy#file=` treats writable path-like objects such as `Pathname` as paths
  instead of caller-owned IOs, so the response is no longer truncated on every
  write.
* MIME part headers now reject CR, LF, and NUL bytes instead of passing them
  verbatim to libcurl. Empty header lines are dropped, so assigning an empty
  string clears the part headers instead of adding an empty header line.
* `CURLOPT_COPYPOSTFIELDS` values are now NUL-terminated, and assigning `nil`
  passes a NULL pointer instead of a zero-length buffer.
* `Easy#url=` and `Easy#postfields=` only update the Ruby-side value after
  libcurl accepts the option, so a rejected value cannot leave the accessors
  describing state the handle never received. `Easy#postfields=` also retains
  the normalized string libcurl points at, so non-String bodies cannot be
  collected mid-transfer.
* `Easy#cleanup` drops references to native-backed strings, lists, MIME/URL
  handles, blobs, and callbacks after freeing the handle.
* `Multi#cleanup` now releases the native multi handle even when detaching an
  easy handle or closing a streamed response fails, and keeps multi ownership
  on an easy handle whose native detach failed so it cannot be reused.
* `Multi#handle` and `Multi#cleanup` now enforce fork safety before allocating
  or releasing a native multi handle, and `Easy#reset`/`#perform` validate the
  handle before clearing response state, so a cleaned up or inherited handle
  cannot truncate a response file or discard the previous result while raising.
* `Easy#cleanup` frees the native handle even when closing a streamed response
  fails, and `Multi#add` closes an open response stream when the easy handle is
  unusable or the native add fails.
* MIME part and request header lists detect a failed `curl_slist_append`
  allocation (FFI reports a NULL pointer, not `nil`) and free the partially
  built list before installing it.
* Fixed the `:string_escape_null` option type to resolve
  `Ethon::Easy::Util` instead of an undefined constant.
* Added byte-exact binary transfer tests, a full option-table cross-check
  against libcurl's own metadata, multipart round-trip tests, end-to-end
  coverage for the `curl_multi_wait` and `select` fallbacks, and a multi
  response-isolation test.
* Reusing an `Easy` no longer leaks the previous custom HTTP method or a
  stale `CURLOPT_CURLU` handle. `Easy#url=` clears a URL handle, `Easy#curlu=`
  clears the string URL, and `Easy#reset` detaches the share before releasing
  it.
* GET requests with a body send the body again; the method reset only applies
  to empty GET requests.
* MIME parts keep a caller-provided header slist alive until libcurl replaces
  it.
* `Curl::Share#share` and `#unshare` now reject unknown or non-symbol/string
  data types with `Ethon::Errors::InvalidValue`.
* `Easy#header` and `Easy#each_header` accept an array of header origins as
  documented.
* `Easy#cleanup` is terminal; using the handle afterwards raises
  `Ethon::Errors::EthonError` instead of silently sending requests without
  callbacks.
* Exceptions raised while buffering response headers are now captured and
  re-raised after the transfer, matching the body and debug callbacks.
  ([#316](https://github.com/typhoeus/ethon/pull/316))
* `Easy.supports_timeout_ms?` now checks the libcurl version instead of async
  DNS support. ([#319](https://github.com/typhoeus/ethon/pull/319))
* Requests no longer set `CURLOPT_HTTPPOST` on libcurl builds configured with
  `--disable-form-api`, where the option does not exist.
  ([#349](https://github.com/typhoeus/ethon/pull/349))
* Corrected the native option number for `tcp_fastopen` (`CURLOPT_TCP_FASTOPEN`,
  244) and the string ABI used by `tlsauth_type` and `proxy_tlsauth_type`.
  `:srp` and `"srp"` are normalized to libcurl's required `"SRP"` value.
* String options containing NUL bytes now raise
  `Ethon::Errors::InvalidValue` instead of FFI's `ArgumentError`, and
  fractional values for integer options are rejected. Binary bodies still use
  `copypostfields`.
* Split the progress callback ABI into `CURLOPT_PROGRESSFUNCTION` (`double`) and
  `CURLOPT_XFERINFOFUNCTION` (`curl_off_t`), and select it using libcurl's
  numeric version instead of string comparison.
* Changing `escape` or `params_encoding` after a query string was built now
  rebuilds the cached pairs and string.
* Read callbacks now report the number of bytes actually read, handle
  short-reading IO bodies, and correctly start from an IO's current position.
* Duplicating an `Easy` now rebinds its response, read, progress, and custom
  callbacks to the copy instead of leaving them pointing at the original
  handle, starts with a clean result/callback-error state, and no longer
  aliases the original MIME structure.
* Custom HTTP verbs that collide with top-level Ruby constants no longer
  resolve to those constants.
* `Easy#reset` now clears multipart state, request headers, retained read
  callbacks, and pending callback errors. `Easy#request_headers` exposes the
  request headers without colliding with the `on_headers` callback.
* `Easy#reset` now refuses to reset a handle that is still attached to a
  `Multi`, matching `Easy#cleanup`.
* `Easy#perform`/`#reset`/`#cleanup`/`#dup` and `Multi#perform`/
  `#socket_action`/`#cleanup` now reject reentrant calls made from callbacks
  while the handle is still active.
* Reading `#on_body` without a block, or after clearing the callback list, no
  longer disables response body buffering.
* Multi no longer mutates the caller's options, validates `execution_mode`, and
  no longer raises when `running_count` is nil. Finalizers no longer emit
  `ThreadError`/`SignalException` warnings.
* Windows `fd_set` now uses pointer-sized socket entries.
* Added libcurl 8.23 options (`CURLOPT_ECH`, `CURLOPT_TCP_KEEPCNT`,
  `CURLOPT_UPLOAD_FLAGS`, `CURLOPT_SSL_SIGNATURE_ALGORITHMS`, and the
  `CURLOPT_HTTPSIG_*` family), the newer `CURLINFO_*` entries, and
  `CURLUE_BACKSLASH`/`CURLU_GET_EMPTY`/`CURLU_NO_GUESS_SCHEME`.
* Fixed the test server's keep-alive limits, cutting the suite from ~35s to
  ~5s, and added coverage for the option table, callbacks, reset behavior,
  Multi message handling, and libcurl info ownership.
* Removing an `Easy` that streams its response to a file from a `Multi`, or a
  failed `Multi#add`, now closes the file instead of leaving it open until GC.
* `Multi#dup` and `Multi#clone` now raise `TypeError` instead of returning a
  shallow copy that shares the native multi handle and easy-handle stack with
  the original.
* `Easy#file=` validates the easy handle before opening a path, so a cleaned up
  or fork-inherited handle cannot truncate the destination while raising.

## 0.19.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.18.0...v0.19.0)

This is a minor release under Semantic Versioning. Before 1.0, a minor release
may include incompatible API changes. Review the breaking changes before
upgrading.

### Breaking changes

* Unsupported libcurl callback ABIs now raise `NotImplementedError` instead of
  being registered with the generic read/write callback signature. This affects
  low-level setters such as `ioctlfunction=`, `seekfunction=`, and
  `opensocketfunction=`. ([#281](https://github.com/typhoeus/ethon/pull/281))
* Fatal errors returned by `curl_multi_perform` now raise
  `Ethon::Errors::MultiPerform` instead of allowing Multi execution to continue
  with invalid state. ([#286](https://github.com/typhoeus/ethon/pull/286))
* Easy and Multi handles created before a `fork` can no longer be used or
  cleaned up in the child process. Ethon now raises
  `Ethon::Errors::ForkSafety`; if libcurl was initialized before forking, use
  `fork` plus `exec`, otherwise create handles after forking.
  ([#295](https://github.com/typhoeus/ethon/pull/295))
* Unknown named enum and bitmask option values now raise
  `Ethon::Errors::InvalidValue` instead of silently becoming `0`. Strings and
  symbols are accepted equivalently, and direct integer values remain
  supported. ([#300](https://github.com/typhoeus/ethon/pull/300))
* Exceptions raised by `on_body` callbacks are now consistently re-raised for
  both Easy and Multi transfers, including when verbose mode is enabled.
  Applications that relied on these exceptions being swallowed must handle
  them explicitly. ([#294](https://github.com/typhoeus/ethon/pull/294))

### Behavior changes

* Empty HTTP header values now follow libcurl semantics: `"Accept" => ""`
  suppresses libcurl's default header, while `"X-Empty;" => ""` sends an empty
  header. ([gonubana](https://github.com/gonubana),
  [#225](https://github.com/typhoeus/ethon/pull/225))

### Enhancements

* Added opt-in `CURLOPT_ERRORBUFFER` support through `Easy#errorbuffer=` and
  `Easy#error_message`, including reset, duplication, Multi, and Mirror support.
  ([Adrien Rey-Jarthon](https://github.com/jarthod),
  [#277](https://github.com/typhoeus/ethon/pull/277))
* Added `Easy#file=` and `Easy#writedata=` to stream response bodies to a path
  or writable Ruby object without accumulating the body in memory. The original
  implementation and authorship were preserved from PR #100.
  ([Seth Madison](https://github.com/baconz),
  [#298](https://github.com/typhoeus/ethon/pull/298))
* Added block-based `Easy#debugfunction` observers while preserving Ethon's
  internal debug collection and safely propagating callback errors.
  ([Kai Lieth](https://github.com/klieth),
  [#154](https://github.com/typhoeus/ethon/pull/154))
* Added `Easy#ssl_engines`, `Easy#cookielist`, and `Easy#certinfo`. Slist
  results are copied and freed according to libcurl ownership rules, while
  certificate lists are copied without freeing libcurl-owned memory. The
  relevant implementation and authorship were preserved from PR #74.
  ([Jethro Beekman](https://github.com/jethrogb),
  [#299](https://github.com/typhoeus/ethon/pull/299))
* Added multipart PUT support. ([#292](https://github.com/typhoeus/ethon/pull/292))
* Released the Ruby GVL around `curl_multi_perform` and native handle cleanup.
  ([Vladimir Shteinman](https://github.com/Bobochka),
  [#278](https://github.com/typhoeus/ethon/pull/278))
* Added libcurl error codes 89 through 101.
  ([Adrien Rey-Jarthon](https://github.com/jarthod),
  [#276](https://github.com/typhoeus/ethon/pull/276))
* Added support for current Windows libcurl DLL names: `libcurl-4`,
  `libcurl-x64`, and `libcurl-arm64`.
  ([Shizuo Fujita](https://github.com/Watson1978),
  [#271](https://github.com/typhoeus/ethon/pull/271))
* Added `ETHON_CURL_LIBS` to override the native libcurl library names.
  ([Sergey Tarasov](https://github.com/dzirtusss),
  [#235](https://github.com/typhoeus/ethon/pull/235))

### Fixes and hardening

* Reworked Easy, Multi, slist, and multipart native ownership around typed,
  PID-aware pointers; removed unsafe Ruby finalizers and prevented inherited
  native cleanup after forks. ([#280](https://github.com/typhoeus/ethon/pull/280),
  [#287](https://github.com/typhoeus/ethon/pull/287),
  [#295](https://github.com/typhoeus/ethon/pull/295))
* Retained option callbacks and multipart forms for the full period in which
  libcurl may call or read them. ([#282](https://github.com/typhoeus/ethon/pull/282),
  [#284](https://github.com/typhoeus/ethon/pull/284))
* Kept Multi's Ruby stack consistent when native add/remove operations fail or
  callbacks raise. ([#285](https://github.com/typhoeus/ethon/pull/285))
* Fixed the `curl_version_info` enum ABI and Multi's
  `CURLMOPT_MAX_TOTAL_CONNECTIONS` option number.
  ([#279](https://github.com/typhoeus/ethon/pull/279),
  [#283](https://github.com/typhoeus/ethon/pull/283))
* Replaced deprecated `getdtablesize` usage with `Etc.sysconf`, with a resource
  limit fallback and the existing `ETHON_FD_SIZE` override.
  ([#296](https://github.com/typhoeus/ethon/pull/296))
* Skipped NTLM integration specs when the installed libcurl has no NTLM support.
  ([Felix Yan](https://github.com/felixonmars),
  [#275](https://github.com/typhoeus/ethon/pull/275))

### Documentation and maintenance

* Documented thread, callback, signal, and fork safety requirements.
  ([#297](https://github.com/typhoeus/ethon/pull/297))
* Corrected `CURLMOPT_PIPELINING` documentation to describe its integer bitmask
  values. ([Bernard Mak](https://github.com/b2mak),
  [#239](https://github.com/typhoeus/ethon/pull/239))
* Updated curl documentation and repository links.
  ([Olle Jonsson](https://github.com/olleolleolle),
  [#237](https://github.com/typhoeus/ethon/pull/237))
* Removed stale test-server entry points.
  ([Vít Ondruch](https://github.com/voxik),
  [#256](https://github.com/typhoeus/ethon/pull/256))
* Expanded CI through Ruby 4.0, retained required Ruby 2.6 coverage, added a
  master-only latest-libcurl build, and reduced matrix setup time.
  ([Geremia Taglialatela](https://github.com/tagliala),
  [#274](https://github.com/typhoeus/ethon/pull/274),
  [#288](https://github.com/typhoeus/ethon/pull/288),
  [#289](https://github.com/typhoeus/ethon/pull/289),
  [#290](https://github.com/typhoeus/ethon/pull/290),
  [#291](https://github.com/typhoeus/ethon/pull/291),
  [#293](https://github.com/typhoeus/ethon/pull/293))

## 0.18.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.17.0...v0.18.0)

* Fixed verbose mode attempting to print binary SSL data by replacing it with a summary.
  ([Felipe Mesquita](https://github.com/felipedmesquita), [#265](https://github.com/typhoeus/ethon/pull/265))
* Fixed `on_headers` callbacks being called once per header line instead of once for all headers.
  ([Felipe Mesquita](https://github.com/felipedmesquita), [#264](https://github.com/typhoeus/ethon/pull/264))
* Stabilized test server boot on macOS by fixing IPv6/IPv4 localhost resolution and preventing orphaned processes.
  ([Geremia Taglialatela](https://github.com/tagliala), [#261](https://github.com/typhoeus/ethon/pull/261))
* Added `logger` to runtime dependencies for Ruby 3.5+ compatibility.
  ([Geremia Taglialatela](https://github.com/tagliala), [#259](https://github.com/typhoeus/ethon/pull/259))
* Opted-in for MFA requirement explicitly by adding `rubygems_mfa_required` metadata.
  ([Geremia Taglialatela](https://github.com/tagliala), [#257](https://github.com/typhoeus/ethon/pull/257))
* Removed redundant encoding and require_relative checks.
  ([Geremia Taglialatela](https://github.com/tagliala), [#258](https://github.com/typhoeus/ethon/pull/258))

## 0.17.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.16.0...v0.17.0)

* Require Ruby 2.6+ and simplify Gemfile.
  ([Felipe Mesquita](https://github.com/felipedmesquita), [#255](https://github.com/typhoeus/ethon/pull/255))
* Fixed mismatched libcurl error codes in `easy_codes` array.
  ([Felipe Mesquita](https://github.com/felipedmesquita), [#253](https://github.com/typhoeus/ethon/pull/253))
* Add Ruby 3.3 and 3.4, remove Ruby 2.5 from CI matrix.
  ([Felipe Mesquita](https://github.com/felipedmesquita), [#252](https://github.com/typhoeus/ethon/pull/252))
* Skip test due to libcurl 8.7.x bug in CURLINFO_REQUEST_SIZE.
  ([Felipe Mesquita](https://github.com/felipedmesquita), [#251](https://github.com/typhoeus/ethon/pull/251))
* Use `Rackup::Handler.default` for Rack 3 compatibility.
  ([Vít Ondruch](https://github.com/voxik), [#244](https://github.com/typhoeus/ethon/pull/244))
* Add Ruby 3.1 and 3.2 to the test matrix.
  ([Orien Madgwick](https://github.com/orien), [#228](https://github.com/typhoeus/ethon/pull/228))
* Remove development and test files from the gem package.
  ([Orien Madgwick](https://github.com/orien), [#227](https://github.com/typhoeus/ethon/pull/227))
* Fix missing parenthesis in example.
  ([Aleksey Tsalolikhin](https://github.com/atsalolikhin-spokeo), [#226](https://github.com/typhoeus/ethon/pull/226))

## 0.16.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.15.0...v0.16.0)

* Added `redirect_url` value to available informations and `Easy::Mirror`.
  ([Adrien Rey-Jarthon](https://github.com/jarthod)

## 0.15.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.14.0...v0.15.0)

## 0.12.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.11.0...v0.12.0)

- Removed deprecated `CURLE_SSL_CACERT` pinned in curl v7.62.0 ([@arku](https://github.com/arku) in [#158](https://github.com/typhoeus/ethon/pull/158))


## 0.11.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.10.1...v0.11.0)

## 0.10.1

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.10.0...v0.10.1)

## 0.10.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.9.1...v0.10.0)

## 0.9.1

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.9.0...v0.9.1)

## 0.9.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.8.1...v0.9.0)

## 0.8.1

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.8.0...v0.8.1)

* Support optional escaping of params.
  ([Tasos Laskos](https://github.com/zapotek)
* `Easy::Mirror`: Reduced object allocations and method calls during info handling.
  ([Tasos Laskos](https://github.com/zapotek)

## 0.8.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.7.3...v0.7.4)

* `Easy::Mirror`: Reduced object allocations and method calls during info handling.
  ([Tasos Laskos](https://github.com/zapotek)

## 0.7.4

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.7.3...v0.7.4)

* Support different array encodings for params.
  ([Marcello Barnaba](https://github.com/ifad), [\#104](https://github.com/typhoeus/ethon/pull/104))
* Programtic access to version infos.
  ([Jonas Wagner](https://github.com/jwagner), [\#90](https://github.com/typhoeus/ethon/pull/90))


## 0.7.3

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.7.2...v0.7.3)

* `Ethon::Curl::FDSet`
    * Set `:fd_array` size to the current MS Windows `FD_SETSIZE` (2048).
        ([Tasos Laskos](https://github.com/zapotek)

* Added `redirect_time` value to available informations and `Easy::Mirror`.
  ([Adrien Jarthon](https://github.com/jarthod)

## 0.7.2

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.7.1...v0.7.2)

* FFI data-types updated to be more correct.

## 0.7.1

* MS Windows determination delegated to `Gem.windows?` for better accuracy.
* FFI data-types updated to work on MS Windows.

## 0.7.0

Not backwards compatible changes:

* `mime-types` are no longer a dependency. The gem will be still used if available to determine the mime type of a file which is uploaded. That means you have to have take care of the gem installation yourself.

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.6.3...v0.7.0)

## 0.6.3

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.6.2...v0.6.3)

## 0.6.2

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.6.1...v0.6.2)

## 0.6.1

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.6.0...v0.6.1)

The changelog entries are coming soon!

## 0.6.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.5.12...v0.6.0)

The changelog entries are coming soon!

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
  [libcurl SASL buffer overflow vulnerability](https://curl.se/docs/adv_20130206.html)).
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
