# frozen_string_literal: true
module Ethon
  module Curls
    # Attach libcurl functions that may not exist in the loaded library.
    module Optional
      # Attach a function, ignoring builds that do not export it.
      def self.attach(base, name, func, args, returns, options = {})
        base.attach_function(name, func, args, returns, options)
      rescue ::FFI::NotFoundError
        nil
      end
    end
  end
end
