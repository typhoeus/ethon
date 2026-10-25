# frozen_string_literal: true
module Ethon
  class Easy

    # This module contains the logic and knowledge about the
    # available options on easy.
    module Options
      CALLBACK_TYPES = [:callback, :debug_callback, :progress_callback, :xferinfo_callback].freeze

      # Ethon installs these callbacks on every handle. Clearing the option must
      # restore Ethon's callback instead of leaving libcurl's default writer
      # active, which would send response bytes to the process's stdout or
      # stderr.
      CALLBACK_DEFAULTS = {
        :writefunction => :body_write_callback,
        :headerfunction => :header_write_callback,
        :debugfunction => :debug_callback
      }.freeze

      attr_reader :url

      def url=(value)
        # libcurl copies the URL, but the accessor must describe the exact
        # string libcurl received. Snapshot it so later caller mutations cannot
        # make #url disagree with the handle, and assign it only once libcurl
        # accepts the value. Do this before touching the URL handle so a
        # rejected value cannot leave it detached.
        snapshot = value.nil? ? nil : value.to_s
        snapshot = snapshot.dup.freeze if snapshot && !snapshot.frozen?

        previous_curlu = @curlu
        if previous_curlu
          Curl.set_option(:curlu, nil, handle)
          @curlu = nil
        end

        begin
          Curl.set_option(:url, snapshot, handle)
        rescue Exception
          # Detaching the URL handle was only necessary to install the new
          # value. Put it back when that value was rejected.
          if previous_curlu
            Curl.set_option(:curlu, previous_curlu, handle)
            @curlu = previous_curlu
          end
          raise
        end
        @url = snapshot
        value
      end

      def escape=( b )
        @escape = b
      end

      def escape?
        return true if !defined?(@escape) || @escape.nil?
        @escape
      end

      def multipart=(b)
        @multipart = b
      end

      def multipart?
        !!@multipart
      end

      def multipart_form=(form)
        self.httppost = form ? form.first.read_pointer : nil
        @multipart_form = form
      rescue Errors::UnsupportedOption
        # CURLOPT_HTTPPOST is compiled out of builds configured with
        # --disable-form-api. Clearing is all that can happen there, because
        # building a form needs the form API itself.
        raise if form

        @multipart_form = form
      end

      # Enables or disables libcurl's error buffer (CURLOPT_ERRORBUFFER),
      # which holds a more detailed error description than #return_message.
      # Read it with #error_message.
      #
      # @example Enable the error buffer.
      #   easy.errorbuffer = true
      #
      # @param [ Boolean ] value True to enable, false to disable.
      #
      # @return [ Boolean ] The value.
      def errorbuffer=(value)
        if value
          @error_buffer ||= FFI::MemoryPointer.new(:char, Curl.easy_options(nil)[:errorbuffer][:opts])
          @error_buffer.put_char(0, 0)
          Curl.set_option(:errorbuffer, @error_buffer, handle)
          handle.error_buffer = @error_buffer
        else
          Curl.set_option(:errorbuffer, nil, handle)
          handle.error_buffer = nil
        end
        @error_buffer_enabled = !!value
        value
      end

      # Returns the error message libcurl stored in the error buffer during
      # the last transfer, or nil if it is empty or #errorbuffer= isn't enabled.
      #
      # @example Get the error message.
      #   easy.error_message
      #
      # @return [ String, nil ] The error message.
      def error_message
        return unless @error_buffer_enabled
        message = @error_buffer.read_string
        message unless message.empty?
      end

      # Enables or disables libcurl's progress callback invocation. libcurl
      # requires CURLOPT_NOPROGRESS to be 0 before it calls a progress
      # callback, so remember the value to restore it when the native handle
      # is replaced.
      #
      # @example Enable progress callbacks.
      #   easy.noprogress = 0
      #
      # @param [ Boolean, Integer ] value The value to set.
      #
      # @return [ Boolean, Integer ] The value.
      def noprogress=(value)
        Curl.set_option(:noprogress, value, handle)
        @noprogress_value = value
        value
      end

      # CURLOPT_TLSAUTH_TYPE and CURLOPT_PROXY_TLSAUTH_TYPE take a string, not
      # an enum. Normalize the historical symbol API and libcurl's required
      # "SRP" spelling.
      def tlsauth_type=(value)
        Curl.set_option(:tlsauth_type, tlsauth_type_value(value), handle)
        value
      end

      def proxy_tlsauth_type=(value)
        Curl.set_option(:proxy_tlsauth_type, tlsauth_type_value(value), handle)
        value
      end

      Curl.easy_options(nil).each do |opt, props|
        # postfields= is defined below because libcurl does not copy the string.
        next if opt == :postfields

        method_name = "#{opt}=".freeze
        unless method_defined? method_name
          if CALLBACK_TYPES.include?(props[:type])
            default_callback = CALLBACK_DEFAULTS[opt]
            define_method(method_name) do |value|
              native_value = value
              native_value = send(default_callback) if value.nil? && default_callback
              Curl.set_option(opt, native_value, handle)
              # Do not retain Ethon's internal callback as if the caller had
              # assigned it; a duplicate must install its own callback.
              retain_callback(opt, value)
              value
            end
          elsif props[:type] == :blob
            define_method(method_name) do |value|
              Curl.set_option(opt, value, handle)
              if value
                (@blobs ||= {})[opt] = value
              elsif @blobs
                @blobs.delete(opt)
              end
              value
            end
          elsif props[:type] == :curl_slist
            # libcurl keeps the list pointer, so retain the wrapper in case it
            # owns the native list. Clearing the option can release it.
            define_method(method_name) do |value|
              Curl.set_option(opt, value, handle)
              if value
                (@slists ||= {})[opt] = value
              elsif @slists
                @slists.delete(opt)
              end
              value
            end
          else
            define_method(method_name) do |value|
              Curl.set_option(opt, value, handle)
              value
            end
          end
        end
        next if props[:type] != :callback || method_defined?(opt)
        define_method(opt) do |&block|
          send(method_name, block)
          nil
        end
      end

      # libcurl does not copy CURLOPT_POSTFIELDS, so keep an immutable snapshot
      # of the bytes alive for as long as the handle may reference it. The
      # native option takes a pointer, which lets the body contain NUL bytes.
      # Retain the buffer only once the option was accepted. Mutating a caller's
      # string afterwards may reallocate it, so libcurl must not point at that
      # buffer.
      #
      # CURLOPT_POSTFIELDSIZE survives between requests. Updating it here keeps
      # libcurl from reading an earlier, larger body length out of the new
      # buffer.
      def postfields=(value)
        if value.nil?
          Curl.set_option(:postfields, nil, handle)
          @postfields = nil
          @postfields_pointer = nil
          # -1 is libcurl's default: the body ends at the first NUL.
          Curl.set_option(:postfieldsize, -1, handle)
        else
          string = value.to_s
          string = string.dup.freeze unless string.frozen?
          pointer = FFI::MemoryPointer.new(:char, string.bytesize + 1)
          pointer.put_bytes(0, string)
          pointer.put_char(string.bytesize, 0)
          Curl.set_option(:postfields, pointer, handle)
          @postfields = string
          @postfields_pointer = pointer
          Curl.set_option(:postfieldsize, string.bytesize, handle)
        end
        value
      end

      # Observe libcurl debug messages without replacing Ethon's internal
      # debug callback. The block receives the native CURL_DEBUGFUNCTION
      # arguments and is called only when verbose mode is enabled.
      #
      # @example Observe debug messages.
      #   easy.debugfunction { |handle, type, data, size, user_data| }
      #
      # @param [ Block ] block The block to execute, or no block to clear it.
      def debugfunction(&block)
        @user_debug_callback = block
        nil
      end

      private

      def initialize_copy(other)
        super
        @procs = @procs.dup if @procs
        @blobs = @blobs.dup if @blobs
        @slists = @slists.dup if @slists
        @on_complete = @on_complete.dup if @on_complete
        @on_headers = @on_headers.dup if @on_headers
        @on_body = @on_body.dup if @on_body
        @on_progress = @on_progress.dup if @on_progress
        @headers = @headers.dup.freeze if @headers
      end

      def tlsauth_type_value(value)
        case value.to_s.downcase
        when "", "none"
          nil
        when "srp"
          "SRP"
        else
          value
        end
      end

      def retain_callback(option, callback)
        if option == :readfunction
          # A callback installed directly by the user does not describe the
          # retained body and must not be replaced when the Easy is duplicated.
          unless callback && callback.equal?(@read_callback)
            @request_body = nil
            @request_body_start = nil
          end
          @read_callback = callback
        end

        # Setting the option that backs on_progress replaces or clears the
        # internal callback. Other progress options lose to XFERINFOFUNCTION.
        if option == @internal_progress_option
          @progress_source = callback ? :custom : nil
        end

        if callback.nil?
          @procs.delete(option) if @procs
        else
          (@procs ||= {})[option] = callback
        end
      end
    end
  end
end
