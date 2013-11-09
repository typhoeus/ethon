module Ethon
  module Curl
    # :nodoc:
    class MsgData < ::FFI::Union
      layout :whatever, :pointer, :code, :easy_code
    end

    # :nodoc:
    class Msg < ::FFI::Struct
      layout :code, :msg_code, :easy_handle, :pointer, :data, MsgData
    end

    # :nodoc:
    class FDSet < ::FFI::Struct
      if Curl.windows?
        layout :fd_count, :u_int,
               :fd_array, [:u_int, 64] # 2048 FDs

        def clear; self[:fd_count] = 0; end
      else
        # FD Set size.
        FD_SETSIZE = ::Ethon::Libc.getdtablesize
        layout :fds_bits, [:long, FD_SETSIZE / ::FFI::Type::LONG.size]

        # :nodoc:
        def clear; super; end
      end
    end

    # :nodoc:
    class Timeval < ::FFI::Struct
      layout :sec, :time_t,
             :usec, :suseconds_t
    end
    
    # :nodoc:
    class Slist < ::FFI::ManagedStruct
      layout :data, :string,
             :next, self.ptr

      def initialize(pointer=nil)
        super(pointer)
        # Only call release on things returned by slist_append
        pointer().autorelease=false
      end
      
      def to_a
        cur=self
        ret=[]
        loop do
          ret << cur[:data]
          break if cur[:next].null?
          cur=cur[:next]
          break if cur[:data].nil?
        end
        ret
      end

      def self.[](ary)
        slist=nil
        ary.each do |v|
          slist=Curl.slist_append(slist,v)
        end
        # Autorelease the final value returned by slist_append
        slist.pointer.autorelease=true unless slist.nil?
        slist
      end

      def self.release(ptr)
        Curl.slist_free_all_ptr(ptr)
      end
    end
  end
end
