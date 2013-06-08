module Ethon
  class Easy

    # This module contains the logic and knowledge about the
    # available options on easy.
    module Options
      attr_reader :url

      def url=(value)
        @url = value
        Curl.set_option(:url, value, handle)
      end
      
      Curl.easy_options.each do |opt,_|
        eval %Q<
          def #{opt}=(value)
            Curl.set_option(:#{opt}, value, handle)
          end
        > unless method_defined? opt.to_s+"="
      end
    end
  end
end
