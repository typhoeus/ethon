# frozen_string_literal: true
module Ethon
  module Curl

    # CURLOPT_SHARE is a pointer to a CURLSH handle.
    Ethon::Curls::Options.option(:easy, :share, :ffipointer, 100)

    # Thin wrapper around libcurl's share API.
    class Share < OwnedPointer
      def self.native_release(pointer)
        Curl.share_cleanup(pointer) if Curl.respond_to?(:share_cleanup)
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

      private

      def setopt(option, data)
        check_pid!
        value = Curl::LockData[data.to_sym]
        code = Curl.share_setopt(self, option, :long, value)
        raise Errors::Share.new(code) unless code == :ok

        code
      end
    end
  end
end
