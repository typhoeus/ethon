require 'orthos/multies/stack'
require 'orthos/multies/operations'

module Orthos
  class Multi
    include Orthos::Multies::Stack
    include Orthos::Multies::Operations

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
