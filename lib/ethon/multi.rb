require 'ethon/multi/stack'
require 'ethon/multi/operations'
require 'ethon/multi/options'

module Ethon

  # This class represents libcurl multi.
  class Multi
    include Ethon::Multi::Stack
    include Ethon::Multi::Operations
    include Ethon::Multi::Options

    class << self

      # Frees the libcurl multi handle.
      #
      # @example Free multi.
      #   Multi.finalizer(multi)
      #
      # @param [ Multi ] multi The multi to free.
      def finalizer(multi)
        proc {
          Curl.multi_cleanup(multi.handle)
        }
      end
    end

    # Create a new multi. Initialize curl in case
    # it didn't happen before.
    #
    # @return [ Multi ] The new multi.
    def initialize(options = {})
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      set_attributes(options)
      init_vars
    end

    # Set given options.
    #
    # @example Set options.
    #   multi.set_attributes(options)
    #
    # @param [ Hash ] options The options.
    #
    # @raise InvalidOption
    #
    # @see initialize
    def set_attributes(options)
      options.each_pair do |key, value|
        unless respond_to?("#{key}=")
          raise Errors::InvalidOption.new(key)
        end
        method("#{key}=").call(value)
      end
    end
  end
end
