# frozen_string_literal: true
require 'ethon/curls/optional'
module Ethon
  module Curls

    # This module contains the functions to be attached in order to work with
    # libcurl.
    module Functions

      # :nodoc:
      def self.extended(base)
        base.attach_function :global_init,                :curl_global_init,         [:long],                        :int
        base.attach_function :global_cleanup,             :curl_global_cleanup,      [],                             :void
        base.attach_function :free,                       :curl_free,                [:pointer],                     :void

        base.attach_function :easy_init,                  :curl_easy_init,           [],                             :pointer
        base.attach_function :easy_cleanup,               :curl_easy_cleanup,        [:pointer],                     :void, blocking: true
        base.attach_function :easy_getinfo,               :curl_easy_getinfo,        [:pointer, :info, :varargs],    :easy_code
        base.attach_function :easy_setopt,                :curl_easy_setopt,         [:pointer, :easy_option, :varargs], :easy_code
        base.instance_variable_set(:@blocking, true)
        base.attach_function :easy_perform,               :curl_easy_perform,        [:pointer],                     :easy_code
        base.attach_function :easy_strerror,              :curl_easy_strerror,       [:easy_code],                   :string
        base.attach_function :easy_escape,                :curl_easy_escape,         [:pointer, :pointer, :int],     :pointer
        base.attach_function :easy_reset,                 :curl_easy_reset,          [:pointer],                     :void
        base.attach_function :easy_duphandle,             :curl_easy_duphandle,      [:pointer],                     :pointer

        Ethon::Curls::Optional.attach(base, :url, :curl_url, [], :pointer, blocking: false)
        Ethon::Curls::Optional.attach(base, :url_cleanup, :curl_url_cleanup, [:pointer], :void, blocking: false)
        Ethon::Curls::Optional.attach(base, :url_dup, :curl_url_dup, [:pointer], :pointer, blocking: false)
        Ethon::Curls::Optional.attach(base, :url_get, :curl_url_get, [:pointer, :url_part, :pointer, :url_flags], :url_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :url_set, :curl_url_set, [:pointer, :url_part, :string, :url_flags], :url_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :url_strerror, :curl_url_strerror, [:url_code], :string, blocking: false)

        base.attach_function :formadd,                    :curl_formadd,             [:pointer, :pointer, :varargs], :int
        base.attach_function :formfree,                   :curl_formfree,            [:pointer],                     :void

        share_attach = lambda do |name, func, args, returns|
          begin
            base.attach_function(name, func, args, returns, blocking: false)
          rescue ::FFI::NotFoundError
            nil
          end
        end
        share_attach.call(:share_init, :curl_share_init, [], :pointer)
        share_attach.call(:share_cleanup, :curl_share_cleanup, [:pointer], :share_code)
        share_attach.call(:share_setopt, :curl_share_setopt, [:pointer, :share_option, :varargs], :share_code)
        share_attach.call(:share_strerror, :curl_share_strerror, [:share_code], :string)

        base.attach_function :multi_init,                 :curl_multi_init,          [],                             :pointer
        base.attach_function :multi_cleanup,              :curl_multi_cleanup,       [:pointer],                     :void, blocking: true
        base.attach_function :multi_add_handle,           :curl_multi_add_handle,    [:pointer, :pointer],           :multi_code
        base.attach_function :multi_remove_handle,        :curl_multi_remove_handle, [:pointer, :pointer],           :multi_code, blocking: true
        base.attach_function :multi_info_read,            :curl_multi_info_read,     [:pointer, :pointer],           Curl::Msg.ptr
        base.attach_function :multi_perform,              :curl_multi_perform,       [:pointer, :pointer],           :multi_code, blocking: true
        base.attach_function :multi_timeout,              :curl_multi_timeout,       [:pointer, :pointer],           :multi_code
        base.attach_function :multi_fdset,                :curl_multi_fdset,         [:pointer, Curl::FDSet.ptr, Curl::FDSet.ptr, Curl::FDSet.ptr, :pointer], :multi_code
        base.attach_function :multi_strerror,             :curl_multi_strerror,      [:int],                         :string
        base.attach_function :multi_setopt,               :curl_multi_setopt,        [:pointer, :multi_option, :varargs], :multi_code
        base.attach_function :multi_socket_action,        :curl_multi_socket_action, [:pointer, :curl_socket_t, :socket_readiness, :pointer], :multi_code, blocking: true

        base.attach_function :version,                    :curl_version,             [],                             :string
        base.attach_function :curl_version_info,          :curl_version_info,        [:int],                         Curl::VersionInfoData.ptr

        Ethon::Curls::Optional.attach(base, :mime_init, :curl_mime_init, [:pointer], :pointer, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_free, :curl_mime_free, [:pointer], :void, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_addpart, :curl_mime_addpart, [:pointer], :pointer, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_name, :curl_mime_name, [:pointer, :string], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_filename, :curl_mime_filename, [:pointer, :string], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_type, :curl_mime_type, [:pointer, :string], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_encoder, :curl_mime_encoder, [:pointer, :string], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_data, :curl_mime_data, [:pointer, :pointer, :size_t], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_filedata, :curl_mime_filedata, [:pointer, :string], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :mime_headers, :curl_mime_headers, [:pointer, :pointer, :int], :easy_code, blocking: false)

        base.attach_function :slist_append,               :curl_slist_append,        [:pointer, :string],            :pointer
        base.attach_function :slist_free_all,             :curl_slist_free_all,      [:pointer],                     :void
        base.instance_variable_set(:@blocking, true)

        Ethon::Curls::Optional.attach(base, :easy_unescape, :curl_easy_unescape, [:pointer, :pointer, :int, :pointer], :pointer, blocking: false)
        Ethon::Curls::Optional.attach(base, :easy_pause, :curl_easy_pause, [:pointer, :int], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :easy_send, :curl_easy_send, [:pointer, :pointer, :size_t, :pointer], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :easy_recv, :curl_easy_recv, [:pointer, :pointer, :size_t, :pointer], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :multi_wait, :curl_multi_wait, [:pointer, :pointer, :uint, :int, :pointer], :multi_code, blocking: true)
        Ethon::Curls::Optional.attach(base, :easy_upkeep, :curl_easy_upkeep, [:pointer], :easy_code, blocking: false)
        Ethon::Curls::Optional.attach(base, :multi_poll, :curl_multi_poll, [:pointer, :pointer, :uint, :int, :pointer], :multi_code, blocking: true)
        Ethon::Curls::Optional.attach(base, :multi_wakeup, :curl_multi_wakeup, [:pointer], :multi_code, blocking: false)

        if Curl.windows?
            base.ffi_lib 'ws2_32'
        else
            base.ffi_lib ::FFI::Library::LIBC
        end

        base.attach_function :select,                                            [:int, Curl::FDSet.ptr, Curl::FDSet.ptr, Curl::FDSet.ptr, Curl::Timeval.ptr], :int
      end

    end
  end
end
