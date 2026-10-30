# Changelog

## Master

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.19.1...master)

### Added

* Add `Ethon::Multipart::Part` for setting the content type and, optionally,
  the filename of a single `multipart/form-data` part. Plain body values keep
  their existing behavior.

## 0.19.1

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.19.0...v0.19.1)

### Behavior changes

* Size a Multi's connection cache to twice the largest number of easy handles
  attached at once. libcurl derives its default `CURLMOPT_MAXCONNECTS` from the
  number of handles attached when a connection is returned, but Ethon detaches
  finished handles immediately, which made the default shrink during a run and
  close connections that later requests could have reused. An explicit
  `maxconnects:` still takes precedence.
  ([#455](https://github.com/typhoeus/ethon/pull/455))

### Fixes and hardening

* Allow `Easy#cleanup` from an `on_complete` callback. The transfer has
  finished and a Multi detaches the handle before its callbacks run, so freeing
  it is safe. Cleanup from body, header, and progress callbacks is still
  rejected. This fixes `:resolve` requests in Typhoeus 1.7.0, which clean up
  instead of pooling to avoid leaking `CURLOPT_RESOLVE` entries.
  ([#456](https://github.com/typhoeus/ethon/pull/456),
  [typhoeus#824](https://github.com/typhoeus/typhoeus/issues/824))

## 0.19.0

[Full Changelog](https://github.com/typhoeus/ethon/compare/v0.18.0...v0.19.0)

Before 1.0, a minor release may include incompatible API changes; review the
breaking changes before upgrading.

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
* Errors from `curl_easy_setopt` and `curl_multi_setopt` are no longer ignored.
  An option the loaded libcurl does not know raises
  `Ethon::Errors::UnsupportedOption`, and other rejected values raise
  `Ethon::Errors::SetOption`. Setting an option such as
  `Easy#http_version = :httpv3` on a libcurl built without HTTP/3 now raises
  instead of silently running with a different configuration.
  `Curl.supports_option?` and `Curl.version_at_least?` can be used to guard
  optional settings.
  ([#343](https://github.com/typhoeus/ethon/pull/343))
* `require 'ethon'` no longer loads mime-types: the registry is loaded on the
  first file upload instead, saving about 2.4 MB and 100 ms per process. Code
  relying on ethon to load `MIME::Types` must now require it itself.
  ([Clément Joubert](https://github.com/czj),
  [#320](https://github.com/typhoeus/ethon/pull/320))
* `Easy#cleanup` and `Multi#cleanup` are terminal, and `Easy#perform` and
  `Easy#reset` raise while the handle is attached to a `Multi`. Applications
  that reused cleaned-up or attached handles must create new ones.
  ([#326](https://github.com/typhoeus/ethon/pull/326),
  [#339](https://github.com/typhoeus/ethon/pull/339),
  [#346](https://github.com/typhoeus/ethon/pull/346),
  [#382](https://github.com/typhoeus/ethon/pull/382))

### Behavior changes

* Verbose debug output is written through `Ethon.logger` at the debug level
  instead of directly to stdout, so request and response headers no longer
  bypass the application's logging configuration. Set
  `Ethon.logger.level = Logger::DEBUG` to keep seeing the messages; response
  body data is not logged.
  ([#390](https://github.com/typhoeus/ethon/pull/390))
* Assigning a new native handle to an `Easy`, including `Easy.new(handle: ...)`
  and `Easy#handle = nil`, now installs Ethon's response callbacks and replays
  the callbacks retained by the object. Constructor options are applied to a
  supplied handle instead of the handle Ethon created and discarded.
  ([#402](https://github.com/typhoeus/ethon/pull/402))
* `Easy#postfields=` now sets `CURLOPT_POSTFIELDSIZE` from the retained bytes
  and restores libcurl's default (`-1`) when the body is cleared. This keeps a
  previous, larger body size from being applied to a shorter body. Set
  `postfieldsize` after `postfields` when sending a prefix or another length.
  ([#403](https://github.com/typhoeus/ethon/pull/403))
* `Easy#postfields=` and `Easy#copypostfields=` now send binary bodies without
  truncating them at the first NUL. A `postfieldsize` larger than the retained
  body raises `Ethon::Errors::InvalidValue` instead of making libcurl read
  past the buffer. Copying a new body without an explicit size sets the exact
  byte length, and clearing the copied body clears the size as well.
  ([#436](https://github.com/typhoeus/ethon/pull/436))
* `Multi.new` now accepts `max_host_connections`, `max_pipeline_length`,
  `content_length_penalty_size`, and `chunk_length_penalty_size`, which were
  already in the multi option table but had no setters.
  ([#444](https://github.com/typhoeus/ethon/pull/444))
* `Share#unlockfunction` callbacks now receive `(handle, data, userp)`, the
  arguments defined by `curl_unlock_function`. They previously used the lock
  callback signature, so the user pointer was read as an access mode and the
  callback received a garbage fourth argument.
  ([#405](https://github.com/typhoeus/ethon/pull/405))
* `Easy#header` and `Easy#each_header` now default to the last request in a
  transfer (`request = -1`), so structured headers describe the response after
  a redirect instead of the first request. Pass `0` to read the first request.
  ([#409](https://github.com/typhoeus/ethon/pull/409))
* `Easy#url=` now stores a frozen snapshot of the string libcurl accepted, and
  `Easy#request_headers` returns a fresh copy of the headers and header values
  that were accepted. Mutating the object passed to a setter no longer makes
  the accessor describe a URL or header set the handle never received.
  ([#413](https://github.com/typhoeus/ethon/pull/413),
  [#418](https://github.com/typhoeus/ethon/pull/418))
* Multipart POST and PUT bodies now use the MIME API when the loaded libcurl
  supports it, and fall back to the deprecated form API on older builds. Part
  names, files, filenames, content types, and regular fields are preserved.
  ([#318](https://github.com/typhoeus/ethon/pull/318))
* Explicit `writefunction`, `headerfunction`, and `debugfunction` options
  passed to `Easy.new` are no longer overwritten by Ethon's internal
  callbacks. A response that aborts from `on_headers` also leaves the buffered
  body empty.
  ([#345](https://github.com/typhoeus/ethon/pull/345))
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
* Added the remaining libcurl 8.7.1 options, info values, blob options, enum
  table entries, and symbolic option values, including DoH, HSTS, Alt-Svc,
  AWS SigV4, SASL, HTTP/3, TLS 1.3 ciphers, proxy headers, and the modern
  `_t`, socket, and pointer info getters.
  ([#307](https://github.com/typhoeus/ethon/pull/307),
  [#308](https://github.com/typhoeus/ethon/pull/308),
  [#309](https://github.com/typhoeus/ethon/pull/309))
* `Multi` now prefers `curl_multi_poll` and `curl_multi_wait` over `select`,
  allocating fd sets only for the fallback. This reduces `Multi.new` memory
  from roughly 199 KB to 7 KB on hosts with a large fd limit and avoids 1ms
  busy-waiting when no descriptor is ready.
  ([#330](https://github.com/typhoeus/ethon/pull/330))
* Added support for current Windows libcurl DLL names: `libcurl-4`,
  `libcurl-x64`, and `libcurl-arm64`.
  ([Shizuo Fujita](https://github.com/Watson1978),
  [#271](https://github.com/typhoeus/ethon/pull/271))
* Added `ETHON_CURL_LIBS` to override the native libcurl library names.
  ([Sergey Tarasov](https://github.com/dzirtusss),
  [#235](https://github.com/typhoeus/ethon/pull/235))

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

* Callback errors are now raised after the transfer has completed, so
  `on_complete` callbacks still run and an `Easy` is removed from its `Multi`
  before the error reaches the caller.
  ([#302](https://github.com/typhoeus/ethon/pull/302))
* A failed `curl_easy_init` or `curl_multi_init` now raises `NoMemoryError`
  immediately instead of wrapping address `0` and deferring the failure.
  ([#305](https://github.com/typhoeus/ethon/pull/305))
* `Easy#headers=` now rejects CR and LF in header names and values with
  `Ethon::Errors::InvalidValue`, so custom headers cannot inject additional
  request headers.
  ([#327](https://github.com/typhoeus/ethon/pull/327))
* PUT bodies now honor `escape: false` instead of always percent-encoding the
  form, matching POST behavior.
  ([#328](https://github.com/typhoeus/ethon/pull/328))
* Numeric option values are now checked against the signed range of the
  native type before being passed to libcurl. Values outside the range raise
  `Ethon::Errors::InvalidValue` instead of a later `RangeError` or FFI error.
  ([#329](https://github.com/typhoeus/ethon/pull/329))
* Request header lists are freed when a later header is invalid or
  `curl_slist_append` fails, and unknown header origins raise
  `Ethon::Errors::InvalidValue` instead of reaching libcurl as `0`.
  ([#347](https://github.com/typhoeus/ethon/pull/347))
* Response stream teardown now only finishes the destination that the completed
  transfer wrote to. A completion callback can schedule the next transfer on
  the same `Easy` (including adding it to a `Multi` with a new or reused
  response file); that destination is no longer closed before the next transfer
  runs. `Multi#add` finishes the previous transfer's stream before preparing
  the next one, and no longer clears a pending callback error while the Easy is
  completing, so the error from the finished transfer is still raised. A
  failing close or flush also no longer replaces the callback or completion
  error, and `Multi#perform` runs `on_complete` before raising a teardown error
  for a handle libcurl already detached.
  ([#431](https://github.com/typhoeus/ethon/pull/431))
* `Multi#assign` rejects a nil or non-integer socket descriptor with
  `Ethon::Errors::InvalidValue` instead of letting FFI raise `TypeError`.
  ([#432](https://github.com/typhoeus/ethon/pull/432))
* `Curl::Url#clone` now duplicates the native URL handle through
  `curl_url_dup`, like `#dup`, instead of raising
  `cannot duplicate FFI::AutoPointer`.
  ([#433](https://github.com/typhoeus/ethon/pull/433))
* Response bodies written to a Ruby IO now retry short writes. Wrapper and
  nonblocking destinations could accept fewer bytes than a chunk without
  raising, and the rest of the chunk was silently lost. A write that reports
  zero progress now fails the transfer, while destinations returning `nil`
  keep their previous behavior.
  ([#443](https://github.com/typhoeus/ethon/pull/443))
* `Easy#file=` now opens a new path before releasing the previous response
  destination. A bad path raises without discarding the file that was already
  configured, so the next `perform` still writes to it.
  ([#439](https://github.com/typhoeus/ethon/pull/439))
* A duplicated `Easy` keeps a configured response file path and opens its own
  stream for the next transfer. A caller-owned IO is still dropped so the two
  handles cannot write into the same object.
  ([#435](https://github.com/typhoeus/ethon/pull/435))
* Multipart forms no longer treat every `Array` value as a file upload. With
  `params_encoding: :none`, ordinary arrays stay data, and file values are
  marked by `Queryable::FileInfo`. Raw `String` bodies are rejected when
  `multipart: true` is requested instead of producing an unnamed part or a
  `NoMethodError`.
  ([#441](https://github.com/typhoeus/ethon/pull/441),
  [#438](https://github.com/typhoeus/ethon/pull/438))
* `InvalidOption`, `UnsupportedOption`, and `SetOption` now inspect the option
  name in their messages, so control characters in an untrusted option key
  cannot inject lines into logs.
  ([#442](https://github.com/typhoeus/ethon/pull/442))
* Corrected API annotations for the `Easy#perform` and `Easy#handle` return
  types, the `Multi` option setter parameter types, and `Multi#socket_action`.
  ([#445](https://github.com/typhoeus/ethon/pull/445))
* Assigning a replacement handle now clears the Ruby-side URL, headers,
  postfields, URL/MIME/slist/blob/share state, response, and return code,
  because the new handle does not have them. `Easy#dup` keeps that state
  because the native duplicate already carries it.
  ([#448](https://github.com/typhoeus/ethon/pull/448))
* `Ethon::Errors::InvalidValue` now escapes the value in its message, so a
  CR or LF in a rejected URL or request-line value can no longer be injected
  into logs that record the exception.
  ([#429](https://github.com/typhoeus/ethon/pull/429))
* The `haproxy_client_ip` option now rejects whitespace. libcurl writes the
  value into the space-separated PROXY protocol line without validating it, so
  a value could add fields or lines to the header.
  ([#428](https://github.com/typhoeus/ethon/pull/428))
* URL values now reject CR and LF before libcurl stores them. libcurl's URL
  API wrote line breaks in paths and queries into the request line verbatim,
  so a URL handle attached with `Easy#curlu=` could inject headers. The string
  setter accepted the same input into `Easy#url` and debug logs before the
  transfer failed. Percent-encoded line breaks remain valid.
  ([#419](https://github.com/typhoeus/ethon/pull/419),
  [#425](https://github.com/typhoeus/ethon/pull/425))
* `Curl::Url.new(existing_url)` now duplicates the handle instead of re-parsing
  its string form. Partial handles can be copied, complete handles are not
  normalized, and non-zero `CURLU_*` flags are rejected for a copy because
  there is no parse step to apply them to.
  ([#420](https://github.com/typhoeus/ethon/pull/420))
* `Multi#add` and `#delete` now roll back their Ruby-side stack when the native
  add or remove raises, `Easy#cleanup` refuses to free an attached handle, and
  `Multi#cleanup` detaches every easy handle and is terminal. Socket and timer
  callbacks are kept until the native multi is cleaned up.
  ([#326](https://github.com/typhoeus/ethon/pull/326))
* `Multi#delete` and `Multi#cleanup` now clear the running count when the stack
  becomes empty, so `Multi#ongoing?` is false after the last handle is removed.
  A handle that libcurl detached before a socket callback raised is no longer
  put back on the stack, so it remains usable.
  ([#421](https://github.com/typhoeus/ethon/pull/421))
* `Easy#reset_transfer_state` clears `return_code`, so adding a used Easy to a
  Multi no longer exposes the previous transfer's result until the new transfer
  completes.
  ([#422](https://github.com/typhoeus/ethon/pull/422))
* Streamed response destinations are flushed before `on_complete`, and
  caller-owned response IOs are flushed when the transfer finishes. Previously
  completion callbacks could read a partial body, and caller-owned file writers
  needed an explicit flush after `perform`.
  ([#424](https://github.com/typhoeus/ethon/pull/424))
* `Easy#log_inspect` redacts credentials in `effective_url` so debug logs do not
  contain URL passwords. The same redaction applies to
  `Mirror#log_informations`; `Easy#effective_url` and `Mirror#options` still
  return the exact URL.
  ([#423](https://github.com/typhoeus/ethon/pull/423))
* Corrected the mirror and query-parameter specs so they assert the constants
  and null-byte cases they describe.
  ([#426](https://github.com/typhoeus/ethon/pull/426))
* Clearing `writefunction`, `headerfunction`, or `debugfunction` now restores
  Ethon's internal callback. libcurl's default callback previously wrote
  response bodies to stdout, stopped collecting response headers, or sent
  verbose output to stderr.
  ([#410](https://github.com/typhoeus/ethon/pull/410))
* `Easy#handle=` now frees the native handle it replaces when this Easy owned
  it, and reattaches the error buffer and `noprogress` setting to the
  replacement. Replacing a handle no longer leaks it, and `#error_message` and
  progress callbacks keep working.
  ([#411](https://github.com/typhoeus/ethon/pull/411))
* `Multi#cleanup` now continues detaching the remaining easy handles after one
  native detach or streamed-response close fails, instead of leaving them
  attached to a cleaned-up Multi. The first error is still raised after
  teardown.
  ([#412](https://github.com/typhoeus/ethon/pull/412))
* `Curl::Mime.new` now rejects handles that are not an `Ethon::Easy`, an
  `Ethon::Curl::EasyHandle`, or a non-null raw easy pointer. Passing another
  owned handle, such as a `Multi`, previously reached `curl_mime_init` and
  could crash the process. Assigning `nil` to a MIME part field now clears it
  instead of setting an empty value or raising.
  ([#414](https://github.com/typhoeus/ethon/pull/414))
* `Curl::Header#origin` now masks every undocumented origin bit, not only the
  single reserved bit current libcurl sets, so the value only contains the
  documented `CURLH_*` bits.
  ([#417](https://github.com/typhoeus/ethon/pull/417))
* `Curl::Slist.build` now rejects CR, LF, and NUL in list lines, so lists used
  for FTP quotes, SMTP recipients, and other verbatim protocol commands cannot
  inject additional commands.
  ([#415](https://github.com/typhoeus/ethon/pull/415))
* `:none` options no longer interpret `false` as enabled, `Ethon.logger = nil`
  falls back to the default logger, and `ETHON_FD_SIZE` is validated and
  rounded up to the native fd_set word size.
  ([#366](https://github.com/typhoeus/ethon/pull/366))
* HTTP helper actions are resolved through an explicit class map, so custom
  verbs that collide with `Ethon::Easy::Http` constants such as `:custom` or
  `:actionable` are sent as custom requests instead of raising.
  ([#363](https://github.com/typhoeus/ethon/pull/363))
* The `select` fallback in `Multi#set_fds` now sleeps for the libcurl timeout
  when no file descriptors are ready instead of busy-waiting in 1ms steps.
  ([#364](https://github.com/typhoeus/ethon/pull/364))
* `Easy#file=` treats writable path-like objects such as `Pathname` as paths
  instead of caller-owned IOs, so the response is no longer truncated on every
  write. ([#360](https://github.com/typhoeus/ethon/pull/360))
* MIME part headers now reject CR, LF, and NUL bytes instead of passing them
  verbatim to libcurl. Empty header lines are dropped, so assigning an empty
  string clears the part headers instead of adding an empty header line.
  ([#362](https://github.com/typhoeus/ethon/pull/362))
* `CURLOPT_COPYPOSTFIELDS` values are now NUL-terminated, and assigning `nil`
  passes a NULL pointer instead of a zero-length buffer.
  ([#359](https://github.com/typhoeus/ethon/pull/359))
* `Easy#url=` and `Easy#postfields=` only update the Ruby-side value after
  libcurl accepts the option, so a rejected value cannot leave the accessors
  describing state the handle never received. `Easy#postfields=` also retains
  a frozen snapshot of the string libcurl points at, so caller mutations cannot
  change the request or leave libcurl reading a reallocated buffer.
  ([#350](https://github.com/typhoeus/ethon/pull/350),
  [#374](https://github.com/typhoeus/ethon/pull/374))
* `Easy#cleanup` drops references to native-backed strings, lists, MIME/URL
  handles, blobs, and callbacks after freeing the handle. It also drops the
  response, progress, and debug callback closures, and `Multi#cleanup` drops
  its retained socket and timer callbacks, so terminal cleanup does not keep
  application state alive.
  ([#365](https://github.com/typhoeus/ethon/pull/365),
  [#381](https://github.com/typhoeus/ethon/pull/381))
* `Multi#cleanup` now releases the native multi handle even when detaching an
  easy handle or closing a streamed response fails, and keeps multi ownership
  on an easy handle whose native detach failed so it cannot be reused.
  ([#352](https://github.com/typhoeus/ethon/pull/352))
* `Multi#handle` and `Multi#cleanup` now enforce fork safety before allocating
  or releasing a native multi handle, and `Easy#reset`/`#perform` validate the
  handle before clearing response state, so a cleaned up or inherited handle
  cannot truncate a response file or discard the previous result while raising.
  ([#358](https://github.com/typhoeus/ethon/pull/358))
* `Easy#handle=` now wraps a raw `FFI::Pointer` in an owned
  `Ethon::Curl::EasyHandle`, so the documented setter produces a usable handle
  that fork safety tracks and `#cleanup` frees. Other owned pointer types and
  null pointers are rejected.
  ([#380](https://github.com/typhoeus/ethon/pull/380))
* `Easy#cleanup` frees the native handle even when closing a streamed response
  fails, and `Multi#add` closes an open response stream when the easy handle is
  unusable or the native add fails.
  ([#358](https://github.com/typhoeus/ethon/pull/358))
* Owned handles now record an explicit `free` and raise
  `Ethon::Errors::EthonError` when used afterwards, instead of dereferencing
  the freed native pointer. This covers Easy and Multi handles, URL, MIME,
  share, and slist wrappers.
  ([#382](https://github.com/typhoeus/ethon/pull/382))
* Option setters, MIME part header assignment, and `Multi#assign` reject freed
  owned pointers instead of handing libcurl a dangling address.
  ([#382](https://github.com/typhoeus/ethon/pull/382),
  [#408](https://github.com/typhoeus/ethon/pull/408))
* MIME part and request header lists detect a failed `curl_slist_append`
  allocation (FFI reports a NULL pointer, not `nil`) and free the partially
  built list before installing it.
  ([#347](https://github.com/typhoeus/ethon/pull/347),
  [#353](https://github.com/typhoeus/ethon/pull/353))
* Fixed the `:string_escape_null` option type to resolve
  `Ethon::Easy::Util` instead of an undefined constant.
  ([#351](https://github.com/typhoeus/ethon/pull/351))
* Added byte-exact binary transfer tests, a full option-table cross-check
  against libcurl's own metadata, multipart round-trip tests, end-to-end
  coverage for the `curl_multi_wait` and `select` fallbacks, and a multi
  response-isolation test.
  ([#354](https://github.com/typhoeus/ethon/pull/354),
  [#355](https://github.com/typhoeus/ethon/pull/355),
  [#356](https://github.com/typhoeus/ethon/pull/356))
* Reusing an `Easy` no longer leaks the previous custom HTTP method or a
  stale `CURLOPT_CURLU` handle. `Easy#url=` clears a URL handle, `Easy#curlu=`
  clears the string URL, and `Easy#reset` detaches the share before releasing
  it.
  ([#323](https://github.com/typhoeus/ethon/pull/323),
  [#325](https://github.com/typhoeus/ethon/pull/325),
  [#344](https://github.com/typhoeus/ethon/pull/344))
* GET requests with a body send the body again; the method reset only applies
  to empty GET requests.
  ([#344](https://github.com/typhoeus/ethon/pull/344))
* MIME parts keep a caller-provided header slist alive until libcurl replaces
  it. ([#368](https://github.com/typhoeus/ethon/pull/368))
* `Curl::Share#share` and `#unshare` now reject unknown or non-symbol/string
  data types with `Ethon::Errors::InvalidValue`.
  ([#338](https://github.com/typhoeus/ethon/pull/338))
* `Easy#header` and `Easy#each_header` accept an array of header origins as
  documented, and reject unknown origins. `Ethon::Curl::Header#origin` no
  longer exposes libcurl's reserved bit, so it matches the documented
  `CURLH_*` values in `Ethon::Curl::HeaderOrigin`.
  ([#347](https://github.com/typhoeus/ethon/pull/347),
  [#383](https://github.com/typhoeus/ethon/pull/383))
* `Easy#cleanup` is terminal; using the handle afterwards raises
  `Ethon::Errors::EthonError` instead of silently sending requests without
  callbacks. ([#382](https://github.com/typhoeus/ethon/pull/382))
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
  ([#307](https://github.com/typhoeus/ethon/pull/307))
* String options containing NUL bytes now raise
  `Ethon::Errors::InvalidValue` instead of FFI's `ArgumentError`, and
  fractional or out-of-range values for integer options are rejected. Binary
  bodies still use `copypostfields`.
  ([#329](https://github.com/typhoeus/ethon/pull/329),
  [#340](https://github.com/typhoeus/ethon/pull/340))
* String options that libcurl writes verbatim into a request line, a protocol
  header, or a protocol command now reject CR and LF. This covers
  `customrequest`, `request_target`, `useragent`, `referer`, `cookie`,
  `accept_encoding`, `range`, and the RTSP, SMTP, and FTP equivalents, which
  could otherwise inject additional headers or commands.
  ([#379](https://github.com/typhoeus/ethon/pull/379))
* Split the progress callback ABI into `CURLOPT_PROGRESSFUNCTION` (`double`) and
  `CURLOPT_XFERINFOFUNCTION` (`curl_off_t`), and select it using libcurl's
  numeric version instead of string comparison.
  ([#307](https://github.com/typhoeus/ethon/pull/307))
* Changing `escape` or `params_encoding` after a query string was built now
  rebuilds the cached pairs and string.
  ([#332](https://github.com/typhoeus/ethon/pull/332))
* Read callbacks now report the number of bytes actually read, handle
  short-reading IO bodies, and correctly start from an IO's current position.
  ([#307](https://github.com/typhoeus/ethon/pull/307),
  [#344](https://github.com/typhoeus/ethon/pull/344))
* Duplicating an `Easy` now rebinds its response, read, progress, and custom
  callbacks to the copy instead of leaving them pointing at the original
  handle, starts with a clean result/callback-error state, and no longer
  aliases the original MIME structure.
  ([#335](https://github.com/typhoeus/ethon/pull/335))
* Custom HTTP verbs that collide with top-level Ruby constants no longer
  resolve to those constants.
  ([#307](https://github.com/typhoeus/ethon/pull/307),
  [#363](https://github.com/typhoeus/ethon/pull/363))
* `Easy#reset` now clears multipart state, request headers, retained read
  callbacks, and pending callback errors. `Easy#request_headers` exposes the
  request headers without colliding with the `on_headers` callback.
  ([#307](https://github.com/typhoeus/ethon/pull/307),
  [#323](https://github.com/typhoeus/ethon/pull/323))
* `Easy#perform` and `Easy#reset` now refuse to run while the handle is still
  attached to a `Multi`, matching `Easy#cleanup`.
  ([#339](https://github.com/typhoeus/ethon/pull/339),
  [#346](https://github.com/typhoeus/ethon/pull/346))
* `Easy#perform`/`#reset`/`#cleanup`/`#dup` and `Multi#perform`/
  `#socket_action`/`#cleanup` now reject reentrant calls made from callbacks
  while the handle is still active.
  ([#342](https://github.com/typhoeus/ethon/pull/342))
* `Easy#perform` now returns the result of the transfer it ran even when an
  `on_complete` callback resets the Easy. Resetting clears `#return_code`, so
  `perform` used to return `nil` after a successful transfer.
  ([#404](https://github.com/typhoeus/ethon/pull/404))
* Reading `#on_body` without a block, or after clearing the callback list, no
  longer disables response body buffering.
  ([#334](https://github.com/typhoeus/ethon/pull/334))
* Multi no longer mutates the caller's options, validates `execution_mode`, and
  no longer raises when `running_count` is nil. Finalizers no longer emit
  `ThreadError`/`SignalException` warnings.
  ([#307](https://github.com/typhoeus/ethon/pull/307))
* Windows `fd_set` now uses pointer-sized socket entries.
  ([#307](https://github.com/typhoeus/ethon/pull/307))
* Added libcurl 8.23 options (`CURLOPT_ECH`, `CURLOPT_TCP_KEEPCNT`,
  `CURLOPT_UPLOAD_FLAGS`, `CURLOPT_SSL_SIGNATURE_ALGORITHMS`, and the
  `CURLOPT_HTTPSIG_*` family), the newer `CURLINFO_*` entries, and
  `CURLUE_BACKSLASH`/`CURLU_GET_EMPTY`/`CURLU_NO_GUESS_SCHEME`.
  ([#341](https://github.com/typhoeus/ethon/pull/341))
* `curl_global_sslset` results now use the `Curl::SslSetCode` enum. An unknown
  backend is `:unknown_backend` instead of `:unsupported_protocol`, and a late
  call is `:too_late` instead of `:failed_init`.
  ([#406](https://github.com/typhoeus/ethon/pull/406))
* Fixed the test server's keep-alive limits, cutting the suite from ~35s to
  ~5s, and added coverage for the option table, callbacks, reset behavior,
  Multi message handling, and libcurl info ownership.
  ([#324](https://github.com/typhoeus/ethon/pull/324))
* Removing an `Easy` that streams its response to a file from a `Multi`, or a
  failed `Multi#add`, now closes the file instead of leaving it open until GC.
  ([#336](https://github.com/typhoeus/ethon/pull/336))
* `Multi#dup` and `Multi#clone` now raise `TypeError` instead of returning a
  shallow copy that shares the native multi handle and easy-handle stack with
  the original.
  ([#372](https://github.com/typhoeus/ethon/pull/372))
* `Easy#file=` validates the easy handle before opening a path, so a cleaned up
  or fork-inherited handle cannot truncate the destination while raising.
  ([#373](https://github.com/typhoeus/ethon/pull/373))
* `Easy#url=` applies a string URL before detaching a `CURLOPT_CURLU` handle,
  so a rejected value leaves the existing URL handle usable.
  ([#370](https://github.com/typhoeus/ethon/pull/370))
* `Multi#add` rejects an Easy that another Multi owns before resetting its
  transfer state or preparing its response stream.
  ([#369](https://github.com/typhoeus/ethon/pull/369))
* MIME part content types and encoders reject CR, LF, and NUL bytes, and the
  other MIME part strings reject NUL bytes with `Ethon::Errors::InvalidValue`
  instead of FFI's `ArgumentError`.
  ([#371](https://github.com/typhoeus/ethon/pull/371))
* `Easy` retains managed `Curl::Slist` values assigned to list-backed options
  such as `resolve`, `connect_to`, and `quote`, so garbage collection cannot
  free a list while libcurl still uses it.
  ([#368](https://github.com/typhoeus/ethon/pull/368))
* Owned native pointers now register in one shared registry, so
  `Curl::OwnedPointer.owners` reports every live handle and the memory usage
  test really checks for native handle leaks. Registration and release are
  synchronized for concurrent handles.
  ([#304](https://github.com/typhoeus/ethon/pull/304),
  [#375](https://github.com/typhoeus/ethon/pull/375))
* `Easy#reset` closes a streamed response file before clearing state, so a
  close failure leaves the handle usable instead of half-reset.
  ([#376](https://github.com/typhoeus/ethon/pull/376))
* `Easy#complete` rejects reentrant calls from its own `on_headers` or
  `on_complete` callbacks instead of recursing until the stack overflows.
  ([#377](https://github.com/typhoeus/ethon/pull/377))
* `Multi#add` no longer opens the response file, resets the transfer state, and
  clears callback errors before libcurl accepted the handle. A failed add
  leaves the previous response and a streamed response file untouched, rolls
  the native attach back when preparing the response stream fails or a socket
  or timer callback raises, and keeps a handle it cannot detach tracked so
  `Multi#cleanup` can retry. Non-`Ethon::Easy` arguments raise `TypeError`.
  ([#386](https://github.com/typhoeus/ethon/pull/386))
* `Easy#dup` and `#clone` now raise `Ethon::Errors::EthonError` when the Easy
  is still attached to a `Multi`, matching `#perform`, `#reset`, and
  `#cleanup`. libcurl requires the source handle to be idle while it is
  cloned, and the copy can never be part of the same multi.
  ([#387](https://github.com/typhoeus/ethon/pull/387))
* `Easy#share=`, `#mime=`, and `#curlu=` now raise `TypeError` for values that
  are not the matching `Ethon::Curl` wrapper and keep the previously assigned
  handle. Other `FFI::Pointer` values were passed to libcurl as a share, MIME,
  or URL handle, where the wrong native layout is undefined behavior.
  ([#388](https://github.com/typhoeus/ethon/pull/388))
* `Curl::Url#set` and `#get` reject unknown part names and flags with
  `Ethon::Errors::InvalidValue` instead of FFI's `ArgumentError`, and values
  containing a NUL byte now raise `Ethon::Errors::InvalidValue` instead of
  silently truncating the URL passed to libcurl. Other values are coerced with
  `to_s`, and `nil` still clears a part.
  ([#391](https://github.com/typhoeus/ethon/pull/391))
* `Multi#easy_handles` returns a frozen snapshot instead of the mutable array
  the multi uses for its bookkeeping. Modifying the returned array previously
  desynchronized the Ruby-side stack from the handles libcurl had attached.
  ([#392](https://github.com/typhoeus/ethon/pull/392))
* `Easy#reset` is allowed from an `on_complete` callback again, restoring
  `Typhoeus::Pool.release`, and a callback error raised during the transfer is
  still raised after the reset. Resets from body, header, and progress
  callbacks stay rejected.
  ([#393](https://github.com/typhoeus/ethon/pull/393))
* MIME part names and filenames reject CR and LF, and the deprecated form API
  validates its field name, filename, and content type, so they cannot inject
  extra part headers on libcurl older than 7.81.
  ([#394](https://github.com/typhoeus/ethon/pull/394))
* `Easy#mirror` omits pointer-valued informations such as
  `CURLINFO_TLS_SSL_PTR`, so mirrored options stay marshalable for cached
  responses. `Easy#tls_ssl_ptr` remains available.
  ([#395](https://github.com/typhoeus/ethon/pull/395))
* The `select` fallback in `Multi#set_fds` releases the GVL while waiting, so
  other Ruby threads can run during the wait.
  ([#396](https://github.com/typhoeus/ethon/pull/396))
* Added `:https3` to `proxytype` and `:earlydata` to `ssl_options` and
  `proxy_ssl_options`.
  ([#397](https://github.com/typhoeus/ethon/pull/397))
* Duplicating an `Easy` keeps the progress callback that was effective on the
  original: `on_progress` no longer disappears when a custom progress function
  is also configured.
  ([#398](https://github.com/typhoeus/ethon/pull/398))
* `Easy#handle=` rejects assignment while the Easy is performing, completing,
  attached to a `Multi`, or cleaned up.
  ([#399](https://github.com/typhoeus/ethon/pull/399))
* Wrapping a native pointer that another `Ethon::Curl` wrapper already owns
  now raises instead of creating a second owner that can use the pointer after
  it is freed. `Easy#handle=` also rejects a handle owned by another Easy.
  ([#401](https://github.com/typhoeus/ethon/pull/401))
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
  ([#297](https://github.com/typhoeus/ethon/pull/297),
  [#303](https://github.com/typhoeus/ethon/pull/303))
* Documented the URL, MIME, share, header, and introspection APIs, rewrote the
  README overview and usage sections, and fixed a stale documentation link and
  parameter names.
  ([#317](https://github.com/typhoeus/ethon/pull/317),
  [#451](https://github.com/typhoeus/ethon/pull/451),
  [#453](https://github.com/typhoeus/ethon/pull/453))
* Corrected `CURLMOPT_PIPELINING` documentation to describe its integer bitmask
  values. ([Bernard Mak](https://github.com/b2mak),
  [#239](https://github.com/typhoeus/ethon/pull/239))
* Updated curl documentation and repository links.
  ([Olle Jonsson](https://github.com/olleolleolle),
  [#237](https://github.com/typhoeus/ethon/pull/237))
* Removed stale test-server entry points.
  ([Vít Ondruch](https://github.com/voxik),
  [#256](https://github.com/typhoeus/ethon/pull/256))
* Corrected deprecation wording, warning text, and error message spelling.
  ([#331](https://github.com/typhoeus/ethon/pull/331),
  [#333](https://github.com/typhoeus/ethon/pull/333))
* Added regression coverage for uncovered Easy and Multi behavior, require-time
  memory use, GVL scheduling, GC and native handle leaks, encoding properties,
  cleanup/MIME/reuse paths, and libcurl 8.23 differences.
  ([#306](https://github.com/typhoeus/ethon/pull/306),
  [#321](https://github.com/typhoeus/ethon/pull/321),
  [#322](https://github.com/typhoeus/ethon/pull/322),
  [#337](https://github.com/typhoeus/ethon/pull/337),
  [#348](https://github.com/typhoeus/ethon/pull/348),
  [#361](https://github.com/typhoeus/ethon/pull/361),
  [#385](https://github.com/typhoeus/ethon/pull/385),
  [#430](https://github.com/typhoeus/ethon/pull/430),
  [#449](https://github.com/typhoeus/ethon/pull/449))
* Expanded CI through Ruby 4.0, retained required Ruby 2.6 coverage, added a
  master-only latest-libcurl build, added Windows coverage, and reduced matrix
  setup time.
  ([Geremia Taglialatela](https://github.com/tagliala),
  [#274](https://github.com/typhoeus/ethon/pull/274),
  [#288](https://github.com/typhoeus/ethon/pull/288),
  [#289](https://github.com/typhoeus/ethon/pull/289),
  [#290](https://github.com/typhoeus/ethon/pull/290),
  [#291](https://github.com/typhoeus/ethon/pull/291),
  [#293](https://github.com/typhoeus/ethon/pull/293),
  [#450](https://github.com/typhoeus/ethon/pull/450))

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
