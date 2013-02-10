module Ethon
  module Curls
    module Protocols
      def protocols
        {
          :http   => 0x00000001,
          :https  => 0x00000002,
          :ftp    => 0x00000004,
          :ftps   => 0x00000008,
          :scp    => 0x00000010,
          :sftp   => 0x00000020,
          :telnet => 0x00000040,
          :ldap   => 0x00000080,
          :ldaps  => 0x00000100,
          :dict   => 0x00001200,
          :file   => 0x00001400,
          :tftp   => 0x00001800,
          :imap   => 0x00011000,
          :imaps  => 0x00012000,
          :pop3   => 0x00014000,
          :pop3s  => 0x00018000,
          :smtp   => 0x00110000,
          :smtps  => 0x00120000,
          :rtsp   => 0x00140000,
          :rtmp   => 0x00180000,
          :rtmpt  => 0x02100000,
          :rtmpe  => 0x02200000,
          :rtmpte => 0x02400000,
          :rtmps  => 0x02800000,
          :rtmpts => 0x21000000,
          :gopher => 0x22000000,
        }
      end
    end
  end
end
