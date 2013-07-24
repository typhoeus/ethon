module Ethon
  class Easy

    # This module contains all the logic around the callbacks,
    # which are needed to interact with libcurl.
    #
    # @api private
    module Callbacks

      # :nodoc:
      def self.included(base)
        base.send(:attr_accessor, *[:response_body, :response_headers])
      end

      # Set writefunction and headerfunction callback.
      # They are called by libcurl in order to provide the header and
      # the body from the request.
      #
      # @example Set callbacks.
      #   easy.set_callbacks
      def set_callbacks
        Curl.set_option(:writefunction, body_write_callback, handle)
        Curl.set_option(:headerfunction, header_write_callback, handle)
        @response_body = ""
        @response_headers = ""
      end

      # Returns the body write callback.
      #
      # @example Return the callback.
      #   easy.body_write_callback
      #
      # @return [ Proc ] The callback.
      def body_write_callback
        @body_write_callback ||= proc {|stream, size, num, object|
          @response_body << stream.read_string(size * num)
          size * num
        }
      end

      # Returns the header write callback.
      #
      # @example Return the callback.
      #   easy.header_write_callback
      #
      # @return [ Proc ] The callback.
      def header_write_callback
        @header_write_callback ||= proc {|stream, size, num, object|
          @response_headers << stream.read_string(size * num)
          size * num
        }
      end

      # Set the read callback. This callback is used by libcurl to
      # read data when performing a PUT request.
      #
      # @example Set the callback.
      #   easy.set_read_callback("a=1")
      #
      # @param [ String ] body The body.
      def set_read_callback(body)
        @request_body_read = 0
        readfunction do |stream, size, num, object|
          size = size * num
          body_size = if body.respond_to?(:bytesize)
            body.bytesize
          elsif body.respond_to?(:size)
            body.size
          elsif body.is_a?(File)
            File.size(body.path)
          end

          left = body_size - @request_body_read
          size = left if size > left

          if size > 0
            chunk = if body.respond_to?(:byteslice)
              body.byteslice(@request_body_read, size)
            elsif body.respond_to?(:read)
              body.read(size)
            else
              body[@request_body_read, size]
            end

            stream.write_string(
              chunk, size
            )
            @request_body_read += size
          end
          size
        end
      end

      # Returns the body read callback.
      #
      # @example Return the callback.
      #   easy.read_callback
      #
      # @return [ Proc ] The callback.
      def read_callback
        @read_callback
      end
    end
  end
end
