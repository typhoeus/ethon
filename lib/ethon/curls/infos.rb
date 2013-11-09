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
          :string   => 0x100000,
          :long     => 0x200000,
          :double   => 0x300000,
          :slist    => 0x400000,
          :certinfo => 0x400000
        }
      end

      # http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTDEBUGFUNCTION
      # https://github.com/bagder/curl/blob/master/include/curl/curl.h#L378
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
      # https://github.com/bagder/curl/blob/master/src/tool_writeout.c#L66 for details
      #
      # @example Return infos.
      #   Ethon::Curl.infos
      #
      # @return [ Hash ] The infos.
      def infos(indices=true)
        Hash[{
          :effective_url =>          [:string,    1],
          :response_code =>          [:long,      2],
          :total_time =>             [:double,    3],
          :namelookup_time =>        [:double,    4],
          :connect_time =>           [:double,    5],
          :pretransfer_time =>       [:double,    6],
          :size_upload =>            [:double,    7],
          :size_download =>          [:double,    8],
          :speed_download =>         [:double,    9],
          :speed_upload =>           [:double,   10],
          :header_size =>            [:long,     11],
          :request_size =>           [:long,     12],
          :ssl_verifyresult =>       [:long,     13],
          :filetime =>               [:long,     14],
          :content_length_download =>[:double,   15],
          :content_length_upload =>  [:double,   16],
          :starttransfer_time =>     [:double,   17],
          :content_type =>           [:string,   18],
          :redirect_time =>          [:double,   19],
          :redirect_count =>         [:long,     20],
          :private =>                [:string,   21],
          :http_connectcode =>       [:long,     22],
          :httpauth_avail =>         [:long,     23],
          :proxyauth_avail =>        [:long,     24],
          :os_errno =>               [:long,     25],
          :num_connects =>           [:long,     26],
          :ssl_engines =>            [:slist,    27],
          :cookielist =>             [:slist,    28],
          :lastsocket =>             [:long,     29],
          :ftp_entry_path =>         [:string,   30],
          :redirect_url =>           [:string,   31],
          :primary_ip =>             [:string,   32],
          :appconnect_time =>        [:double,   33],
          :certinfo =>               [:certinfo, 34],
          :condition_unmet =>        [:long,     35],
          :rtsp_session_id =>        [:string,   36],
          :rtsp_client_cseq =>       [:long,     37],
          :rtsp_server_cseq =>       [:long,     38],
          :rtsp_cseq_recv =>         [:long,     39],
          :primary_port =>           [:long,     40],
          :local_ip =>               [:string,   41],
          :local_port =>             [:long,     42],
        }.map { |k,v| indices ? [k,info_types[v[0]]+v[1]] : [k,v[0]] }]
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
        if easy_getinfo(handle, option, ptr_ptr) == :ok
          ptr=ptr_ptr.read_pointer
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
        if easy_getinfo(handle, option, long_ptr) == :ok
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
        if easy_getinfo(handle, option, double_ptr) == :ok
          double_ptr.read_double
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
        if easy_getinfo(handle, option, ptr_ptr) == :ok
          ret=[]
          ptr=ptr_ptr.read_pointer
          unless ptr.null?
            slist=Curl::Slist.new(ptr)
            ret=slist.to_a
            slist.pointer.free
          end
        end
      end

      # Return info as certinfo array.
      #
      # @example Return info.
      #   Curl.get_info_certinfo(:ssl_engines, easy)
      #
      # @param [ Symbol ] option The option name.
      # @param [ ::FFI::Pointer ] handle The easy handle.
      #
      # @return [ Array ] The info.
      def get_info_certinfo(option, handle)
        if easy_getinfo(handle, option, ptr_ptr) == :ok
          ptr=ptr_ptr.read_pointer
          ptr.null? ? nil : Curl::Certinfo.new(ptr).to_a
        end
      end

      # Return a pointer pointer.
      #
      # @example Return a pointer pointer.
      #   Curl.ptr_ptr
      #
      # @return [ ::FFI::Pointer ] The pointer pointer.
      def ptr_ptr
        @ptr_ptr ||= ::FFI::MemoryPointer.new(:pointer)
      end

      # Return a long pointer.
      #
      # @example Return a long pointer.
      #   Curl.long_ptr
      #
      # @return [ ::FFI::Pointer ] The long pointer.
      def long_ptr
        @long_ptr ||= ::FFI::MemoryPointer.new(:long)
      end

      # Return a double pointer.
      #
      # @example Return a double pointer.
      #   Curl.double_ptr
      #
      # @return [ ::FFI::Pointer ] The double pointer.
      def double_ptr
        @double_ptr ||= ::FFI::MemoryPointer.new(:double)
      end
    end
  end
end
