require 'ethon/multies/stack'
require 'ethon/multies/operations'

module Ethon

  # This class represents libcurl multi.
  class Multi
    include Ethon::Multies::Stack
    include Ethon::Multies::Operations

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
    def initialize
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      init_vars
    end
  end
end
