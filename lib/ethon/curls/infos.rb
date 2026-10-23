# frozen_string_literal: true
module Ethon
  module Curls

    # This module contains logic for the available informations
    # on an easy, eg.: connect_time.
    module Infos

      # Return info types.
      #
      # @example Return info types.
      #   Ethon::Curl.info_types
      #
      # @return [ Hash ] The info types.
      def info_types
        {
          :string =>0x100000,
          :long =>  0x200000,
          :double =>0x300000,
          :slist => 0x400000,
          :ptr =>   0x400000,
          :socket =>0x500000,
          :off_t => 0x600000
        }
      end

      # https://curl.se/libcurl/c/CURLOPT_DEBUGFUNCTION.html
      # https://github.com/curl/curl/blob/master/include/curl/curl.h#L378
      #
      # @example Return debug info types.
      #   Ethon::Curl.debug_info_types
      #
      # @return [ Hash ] The info types available to curl_debug_callback.
      def debug_info_types
        [
          :text, 0,
          :header_in,
          :header_out,
          :data_in,
          :data_out,
          :ssl_data_in,
          :ssl_data_out
        ]
      end

      # Return Info details, refer
      # https://github.com/curl/curl/blob/master/src/tool_writeout.c#L66 for details
      #
      # @example Return infos.
      #   Ethon::Curl.infos
      #
      # @return [ Hash ] The infos.
      def infos
        {
          :size_upload_t =>          info_types[:off_t]  + 7,
          :size_download_t =>        info_types[:off_t]  + 8,
          :speed_download_t =>       info_types[:off_t]  + 9,
          :speed_upload_t =>         info_types[:off_t]  + 10,
          :filetime_t =>             info_types[:off_t]  + 14,
          :content_length_download_t =>info_types[:off_t] + 15,
          :content_length_upload_t =>info_types[:off_t]  + 16,
          :http_version =>           info_types[:long]   + 46,
          :proxy_ssl_verifyresult => info_types[:long]   + 47,
          :scheme =>                 info_types[:string] + 49,
          :total_time_t =>           info_types[:off_t]  + 50,
          :namelookup_time_t =>      info_types[:off_t]  + 51,
          :connect_time_t =>         info_types[:off_t]  + 52,
          :pretransfer_time_t =>     info_types[:off_t]  + 53,
          :starttransfer_time_t =>   info_types[:off_t]  + 54,
          :redirect_time_t =>        info_types[:off_t]  + 55,
          :appconnect_time_t =>      info_types[:off_t]  + 56,
          :retry_after =>            info_types[:off_t]  + 57,
          :effective_method =>       info_types[:string] + 58,
          :proxy_error =>            info_types[:long]   + 59,
          :referer =>                info_types[:string] + 60,
          :cainfo =>                 info_types[:string] + 61,
          :capath =>                 info_types[:string] + 62,
          :xfer_id =>                info_types[:off_t]  + 63,
          :conn_id =>                info_types[:off_t]  + 64,
          :queue_time_t =>           info_types[:off_t]  + 65,
          :used_proxy =>             info_types[:long]   + 66,
          :activesocket =>           info_types[:socket] + 44,
          :tls_ssl_ptr =>            info_types[:ptr]    + 45,
          :effective_url =>          info_types[:string] + 1,
          :response_code =>          info_types[:long]   + 2,
          :total_time =>             info_types[:double] + 3,
          :namelookup_time =>        info_types[:double] + 4,
          :connect_time =>           info_types[:double] + 5,
          :pretransfer_time =>       info_types[:double] + 6,
          :size_upload =>            info_types[:double] + 7,
          :size_download =>          info_types[:double] + 8,
          :speed_download =>         info_types[:double] + 9,
          :speed_upload =>           info_types[:double] + 10,
          :header_size =>            info_types[:long]   + 11,
          :request_size =>           info_types[:long]   + 12,
          :ssl_verifyresult =>       info_types[:long]   + 13,
          :filetime =>               info_types[:long]   + 14,
          :content_length_download =>info_types[:double] + 15,
          :content_length_upload =>  info_types[:double] + 16,
          :starttransfer_time =>     info_types[:double] + 17,
          :content_type =>           info_types[:string] + 18,
          :redirect_time =>          info_types[:double] + 19,
          :redirect_count =>         info_types[:long]   + 20,
          :private =>                info_types[:string] + 21,
          :http_connectcode =>       info_types[:long]   + 22,
          :httpauth_avail =>         info_types[:long]   + 23,
          :proxyauth_avail =>        info_types[:long]   + 24,
          :os_errno =>               info_types[:long]   + 25,
          :num_connects =>           info_types[:long]   + 26,
          :ssl_engines =>            info_types[:slist]  + 27,
          :cookielist =>             info_types[:slist]  + 28,
          :lastsocket =>             info_types[:long]   + 29,
          :ftp_entry_path =>         info_types[:string] + 30,
          :redirect_url =>           info_types[:string] + 31,
          :primary_ip =>             info_types[:string] + 32,
          :appconnect_time =>        info_types[:double] + 33,
          :certinfo =>               info_types[:slist]  + 34,
          :condition_unmet =>        info_types[:long]   + 35,
          :rtsp_session_id =>        info_types[:string] + 36,
          :rtsp_client_cseq =>       info_types[:long]   + 37,
          :rtsp_server_cseq =>       info_types[:long]   + 38,
          :rtsp_cseq_recv =>         info_types[:long]   + 39,
          :primary_port =>           info_types[:long]   + 40,
          :local_ip =>               info_types[:string] + 41,
          :local_port =>             info_types[:long]   + 42,
          :last =>42
        }
      end

      # Return info as string.
      #
      # @example Return info.
      #   Curl.get_info_string(:primary_ip, easy)
      #
      # @param [ Symbol ] option The option name.
      # @param [ ::FFI::Pointer ] handle The easy handle.
      #
      # @return [ String ] The info.
      def get_info_string(option, handle)
        string_ptr = ::FFI::MemoryPointer.new(:pointer)

        if easy_getinfo(handle, option, :pointer, string_ptr) == :ok
          ptr=string_ptr.read_pointer
          ptr.null? ? nil : ptr.read_string
        end
      end

      # Return info as integer.
      #
      # @example Return info.
      #   Curl.get_info_long(:response_code, easy)
      #
      # @param [ Symbol ] option The option name.
      # @param [ ::FFI::Pointer ] handle The easy handle.
      #
      # @return [ Integer ] The info.
      def get_info_long(option, handle)
        long_ptr = ::FFI::MemoryPointer.new(:long)

        if easy_getinfo(handle, option, :pointer, long_ptr) == :ok
          long_ptr.read_long
        end
      end

      # Return info as float
      #
      # @example Return info.
      #   Curl.get_info_double(:response_code, easy)
      #
      # @param [ Symbol ] option The option name.
      # @param [ ::FFI::Pointer ] handle The easy handle.
      #
      # @return [ Float ] The info.
      def get_info_double(option, handle)
        double_ptr = ::FFI::MemoryPointer.new(:double)

        if easy_getinfo(handle, option, :pointer, double_ptr) == :ok
          double_ptr.read_double
        end
      end

      # Return info as a 64-bit integer (curl_off_t).
      def get_info_off_t(option, handle)
        int64_ptr = ::FFI::MemoryPointer.new(:int64)

        if easy_getinfo(handle, option, :pointer, int64_ptr) == :ok
          int64_ptr.read_int64
        end
      end

      # Return info as a curl_socket_t.
      def get_info_socket(option, handle)
        if Curl.windows?
          ptr = ::FFI::MemoryPointer.new(:size_t)
          return unless easy_getinfo(handle, option, :pointer, ptr) == :ok
          ::FFI.type_size(:size_t) == 8 ? ptr.read_uint64 : ptr.read_uint32
        else
          ptr = ::FFI::MemoryPointer.new(:int)
          ptr.read_int if easy_getinfo(handle, option, :pointer, ptr) == :ok
        end
      end

      # Return info as a raw pointer.
      def get_info_ptr(option, handle)
        ptr = ::FFI::MemoryPointer.new(:pointer)

        if easy_getinfo(handle, option, :pointer, ptr) == :ok
          value = ptr.read_pointer
          value unless value.null?
        end
      end

      # Return info as array of strings.
      #
      # @example Return info.
      #   Curl.get_info_slist(:ssl_engines, easy)
      #
      # @param [ Symbol ] option The option name.
      # @param [ ::FFI::Pointer ] handle The easy handle.
      #
      # @return [ Array ] The info.
      def get_info_slist(option, handle)
        result = ::FFI::MemoryPointer.new(:pointer)
        return unless easy_getinfo(handle, option, :pointer, result) == :ok

        pointer = result.read_pointer
        return [] if pointer.null?

        list = Curl::Slist.new(pointer)
        list.to_a
      ensure
        list.free if list
      end

      # Return certificate information copied from libcurl-owned memory.
      def get_info_certinfo(option, handle)
        result = ::FFI::MemoryPointer.new(:pointer)
        return unless easy_getinfo(handle, option, :pointer, result) == :ok

        pointer = result.read_pointer
        pointer.null? ? [] : Curl::Certinfo.new(pointer).to_a
      end
    end
  end
end
