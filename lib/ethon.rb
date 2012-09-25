require 'logger'
require 'ffi'
require 'rbconfig'
require 'thread'
require 'mime/types'
require 'tempfile'

require 'ethon/curl'
require 'ethon/errors'
require 'ethon/easy'
require 'ethon/multi'
require 'ethon/loggable'
require 'ethon/version'

# Ethon is a very simple libcurl.
# It provides direct access to libcurl functionality
# as well as some helpers for doing http requests.
#
# Ethon was extracted from Typhoeus. If you want to
# see how others use Ethon look at the Typhoeus code.
#
# @api private
module Ethon
end
