module Ethon
  class Easy
    # This module contains logic for managing open files on an easy instance
    module Files
      def open_file(path, mode)
        @open_files ||= []
        fh = Libc.ffi_fopen(path, mode)
        @open_files << fh
        fh
      end

      def close_all_files
        @open_files.each {|fh| Libc.ffi_fclose(fh)} unless @open_files.nil?
        @open_files = []
      end
    end
  end
end
