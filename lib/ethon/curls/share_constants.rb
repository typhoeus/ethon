# frozen_string_literal: true
module Ethon
  module Curl
    # CURLSHcode values.
    ShareCode = enum(:share_code, [
      :ok,
      :bad_option,
      :in_use,
      :invalid,
      :nomem,
      :not_built_in,
      :last
    ])

    # CURLSHoption values.
    ShareOption = enum(:share_option, [
      :none,
      :share,
      :unshare,
      :lockfunc,
      :unlockfunc,
      :userdata,
      :last
    ])

    # curl_lock_data values.
    LockData = enum(:lock_data, [
      :none,
      :share,
      :cookie,
      :dns,
      :ssl_session,
      :connect,
      :psl,
      :hsts,
      :last
    ])

    # curl_lock_access values.
    LockAccess = enum(:lock_access, [
      :none,
      :shared,
      :single,
      :last
    ])
  end
end
