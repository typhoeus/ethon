module Orthos
  module Callbacks
    def body_write_callback
      @body_write_callback ||= proc {|stream, size, num, object|
        @response_body << stream.read_string(size * num)
        size * num
      }
    end

    def header_write_callback
      @header_write_callback ||= proc {|stream, size, num, object|
        @response_header << stream.read_string(size * num)
        size * num
      }
    end
  end
end
