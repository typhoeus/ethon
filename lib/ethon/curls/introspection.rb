# frozen_string_literal: true
module Ethon
  module Curl
    class << self
      # Look up a libcurl option by name.
      #
      # @param [ String, Symbol ] name The CURLOPT name.
      #
      # @return [ EasyOptionInfo, nil ] The option metadata.
      def easy_option(name)
        return unless respond_to?(:easy_option_by_name)

        info = easy_option_by_name(name.to_s)
        info.null? ? nil : info
      end

      # Look up a libcurl option by numeric id.
      #
      # @param [ Integer, Symbol ] id The CURLoption id or name.
      #
      # @return [ EasyOptionInfo, nil ] The option metadata.
      def option_by_id(id)
        return unless respond_to?(:easy_option_by_id)

        info = easy_option_by_id(id)
        info.null? ? nil : info
      end

      # Enumerate all libcurl option metadata.
      #
      # @return [ Enumerator, Array ] The metadata.
      def each_easy_option
        unless respond_to?(:easy_option_next)
          raise NotImplementedError, "curl_easy_option_next is not supported by this libcurl"
        end
        return enum_for(:each_easy_option) unless block_given?

        info = easy_option_next(::FFI::Pointer::NULL)
        until info.null?
          yield info
          info = easy_option_next(info)
        end
        self
      end

      def easy_option_list
        each_easy_option.to_a
      end

      # The full version info struct when the runtime supports it.
      #
      # @return [ VersionInfoDataFull, nil ] The full version metadata.
      def version_info_full
        info = version_info
        return unless info[:curl_version] >= 10

        VersionInfoDataFull.new(info.to_ptr)
      end

      # Protocols supported by the loaded libcurl.
      #
      # @return [ Array<String> ] Protocol names.
      def protocols
        string_array(version_info[:protocols])
      end

      # Feature names supported by the loaded libcurl.
      #
      # @return [ Array<String> ] Feature names.
      def feature_names
        info = version_info_full
        return [] unless info

        string_array(info[:feature_names])
      end

      # Read a NULL-terminated array of C strings.
      #
      # @param [ FFI::Pointer, nil ] pointer The array pointer.
      #
      # @return [ Array<String> ] The strings.
      def string_array(pointer)
        return [] if pointer.nil? || pointer.null?

        strings = []
        offset = 0
        loop do
          string = pointer.get_pointer(offset)
          break if string.null?

          strings << string.read_string
          offset += ::FFI.type_size(:pointer)
        end
        strings
      end
    end
  end
end
