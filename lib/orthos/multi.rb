require 'orthos/stack'
require 'orthos/operations/multi'

module Orthos
  class Multi
    include Orthos::Stack
    include Orthos::Operations::Multi

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
