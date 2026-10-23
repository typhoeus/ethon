# frozen_string_literal: true
module Ethon
  module Curl

    # Thin wrapper around libcurl's share API.
    class Share < OwnedPointer
      CALLBACKS_MUTEX = Mutex.new

      attr_reader :lockfunction, :unlockfunction

      def self.native_release(pointer)
        Curl.share_cleanup(pointer) if Curl.respond_to?(:share_cleanup)
      end

      # Callback functions must outlive the Share because libcurl invokes them
      # again from curl_share_cleanup.
      def self.callbacks
        @callbacks ||= {}
      end

      def self.release(pointer)
        super
      ensure
        key = [Process.pid, pointer.address]
        CALLBACKS_MUTEX.synchronize { callbacks.delete(key) }
      end

      # Build the dispatcher on the class so the closure does not retain the
      # Share instance; otherwise the callback registry itself would keep every
      # share handle alive.
      def self.callback_function(callback)
        FFI::Function.new(:void, [:pointer, :int, :int, :pointer], proc do |handle, data, access, userp|
          callback.call(handle, Curl::LockData[data], Curl::LockAccess[access], userp)
        end)
      end

      def initialize
        unless Curl.respond_to?(:share_init)
          raise NotImplementedError, "curl_share_init is not supported by this libcurl"
        end

        pointer = Curl.share_init
        raise NoMemoryError, "curl_share_init failed" if pointer.null?

        super(pointer)
      end

      # Share a data type between easy handles.
      #
      # @param [ Symbol, String ] data One of :cookie, :dns, :ssl_session,
      #   :connect, :psl, or :hsts.
      #
      # @return [ Share ] self
      def share(data)
        setopt(:share, data)
        self
      end

      # Stop sharing a data type.
      #
      # @param [ Symbol, String ] data The data type.
      #
      # @return [ Share ] self
      def unshare(data)
        setopt(:unshare, data)
        self
      end

      # Set the callback libcurl calls before accessing shared data.
      #
      # The block receives the easy handle, the shared data type, the access
      # mode, and the user pointer. libcurl requires lock and unlock callbacks
      # when a share handle is used from more than one thread.
      #
      # @example Lock shared cookies.
      #   share.lockfunction = proc { |handle, data, access, userp| mutex.synchronize { ... } }
      #
      # @param [ Proc, nil ] callback The lock callback.
      #
      # @return [ Proc, nil ] The callback.
      def lockfunction=(callback)
        set_callback(:lockfunc, callback)
      end

      # Set the callback libcurl calls after accessing shared data.
      #
      # @param [ Proc, nil ] callback The unlock callback.
      #
      # @return [ Proc, nil ] The callback.
      def unlockfunction=(callback)
        set_callback(:unlockfunc, callback)
      end

      private

      def setopt(option, data)
        check_pid!
        value = Curl::LockData[data.to_sym]
        raise Errors::Share.new(:bad_option) unless value

        code = Curl.share_setopt(self, option, :long, value)
        raise Errors::Share.new(code) unless code == :ok

        code
      end

      def set_callback(option, callback)
        check_pid!
        unless callback.nil? || callback.is_a?(Proc)
          raise Errors::InvalidValue.new(option, callback)
        end

        # libcurl calls the lock and unlock callbacks again during
        # curl_share_cleanup, so the FFI::Function itself must stay alive.
        function = self.class.callback_function(callback) if callback

        code = Curl.share_setopt(self, option, :pointer, function)
        raise Errors::Share.new(code) unless code == :ok

        key = [Process.pid, address]
        CALLBACKS_MUTEX.synchronize do
          registry = self.class.callbacks[key] ||= {}
          if function
            registry[option] = function
          else
            registry.delete(option)
            self.class.callbacks.delete(key) if registry.empty?
          end
        end

        if option == :lockfunc
          @lockfunction = callback
        else
          @unlockfunction = callback
        end
        callback
      end
    end
  end
end
