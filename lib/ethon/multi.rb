require 'ethon/multies/stack'
require 'ethon/multies/operations'

module Ethon
  class Multi
    include Ethon::Multies::Stack
    include Ethon::Multies::Operations

    class << self
      def finalizer(multi)
        proc {
          Curl.multi_cleanup(multi.handle)
        }
      end
    end

    def initialize
      Curl.init
      ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      init_vars
    end

    def handle
      @handle ||= Curl.multi_init
    end
  end
end
