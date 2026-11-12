# frozen_string_literal: true
require 'logger'
require 'ffi'
require 'thread'
require 'tempfile'

require 'ethon/libc'
require 'ethon/curl'
require 'ethon/curls/mime'
require 'ethon/multipart'
require 'ethon/easy'
require 'ethon/easy/url'
require 'ethon/easy/mime'
require 'ethon/errors'
require 'ethon/curls/introspection'
require 'ethon/easy/headers_api'
require 'ethon/loggable'
require 'ethon/multi'
require 'ethon/version'
require 'ethon/curls/share'
require 'ethon/easy/share'

# Ethon is a very simple libcurl.
# It provides direct access to libcurl functionality
# as well as some helpers for doing http requests.
#
# Ethon was extracted from Typhoeus. If you want to
# see how others use Ethon look at the Typhoeus code.
#
# @see https://www.github.com/typhoeus/typhoeus Typhoeus
#
# @note Please update to the latest libcurl version in order
#   to benefit from all features and bugfixes.
#   https://curl.se/download.html
module Ethon
end
