module Ethon
  module Curls
    module AuthTypes
      def auth_types
        {
          :basic =>       0x01,
          :digest =>      0x02,
          :gssnegotiate =>0x04,
          :ntlm =>        0x08,
          :digest_ie =>   0x10,
          :auto =>        0x1f
        }
      end
    end
  end
end
