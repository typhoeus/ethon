module Ethon
  class Easy

    # This module contains the methods to return informations
    # from the easy handle. See http://curl.haxx.se/libcurl/c/curl_easy_getinfo.html
    # for more information.
    module Informations

      # Holds available informations and their type, which is needed to
      # request the informations from libcurl.
      AVAILABLE_INFORMATIONS=Curl.infos(false)

      AVAILABLE_INFORMATIONS.each do |name, type|
        eval %Q|def #{name}; Curl.send(:get_info_#{type}, :#{name}, handle); end|
      end

      # Returns this curl version supports zlib.
      #
      # @example Return wether zlib is supported.
      #   easy.supports_zlib?
      #
      # @return [ Boolean ] True if supported, else false.
      def supports_zlib?
        !!(Curl.version.match(/zlib/))
      end
    end
  end
end
