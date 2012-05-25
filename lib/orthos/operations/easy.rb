module Orthos
  module Operations
    module Easy
      def perform
        @return_code = Curl.easy_perform(handle)
      end

      def prepare
        set_options
        set_headers
        set_callbacks
      end
    end
  end
end
