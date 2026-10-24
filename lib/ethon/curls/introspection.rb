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
        return unless info && info[:curl_version] >= CURLVERSION_ELEVENTH

        VersionInfoDataFull.new(info.to_ptr)
      end

      # Protocols supported by the loaded libcurl.
      #
      # @return [ Array<String> ] Protocol names.
      def protocols
        string_array(version_info[:protocols])
      end

      # Return whether libcurl knows an option.
      #
      # Easy options are checked against libcurl's own option table on 7.73.0
      # and newer. Older versions cannot answer that question, so it returns
      # `true` for every option Ethon knows. Multi options are only checked
      # against Ethon's table, because libcurl does not expose multi option
      # metadata.
      #
      # @param [ String, Symbol ] name The CURLOPT_* name without the prefix.
      # @param [ Symbol ] type :easy or :multi.
      #
      # @return [ Boolean ] True when the option is available.
      def supports_option?(name, type = :easy)
        name = name.to_sym if name.is_a?(String)
        options = type == :multi ? multi_options(nil) : easy_options(nil)
        option = options[name]
        return false unless option

        if type == :easy && respond_to?(:easy_option_by_id)
          # Resolve by id so Ethon aliases such as :unix_socket are reported
          # correctly; libcurl's by-name lookup only knows canonical names.
          !easy_option_by_id(option[:opt]).null?
        else
          true
        end
      end

      # Check the loaded libcurl version against a dotted version number.
      #
      # @example
      #   Ethon::Curl.version_at_least?("7.66.0")
      #
      # @param [ String ] version The version to compare, for example "7.66.0".
      #
      # @return [ Boolean ] True when libcurl is at least that version.
      def version_at_least?(version)
        parts = version.to_s.split(".").map(&:to_i)
        required = (parts[0].to_i << 16) | (parts[1].to_i << 8) | parts[2].to_i
        version_info[:version_num] >= required
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
