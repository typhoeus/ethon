module Ethon
  module Curls
    module Postredir
      def postredir
        {
          :get_all  => 0x00,
          :post_301 => 0x01,
          :post_302 => 0x02,
          :post_303 => 0x04,
          :post_all => 0x07
        }
      end
    end
  end
end
