# frozen_string_literal: true
require 'ethon/easy/util'
require 'ethon/easy/queryable'

module Ethon
  class Easy

    # This class represents a form and is used to send a payload in the
    # request body via POST/PUT.
    # It handles multipart forms, too.
    #
    # @api private
    class Form
      include Ethon::Easy::Util
      include Ethon::Easy::Queryable

      # Return a new Form.
      #
      # @example Return a new Form.
      #   Form.new({})
      #
      # @param [ Hash ] params The parameter with which to initialize the form.
      #
      # @return [ Form ] A new Form.
      def initialize(easy, params, multipart = nil)
        @easy = easy
        @params = params || {}
        @multipart = multipart
      end

      # Return a pointer to the first form element in libcurl.
      #
      # @example Return the first form element.
      #   form.first
      #
      # @return [ FFI::Pointer ] The first element.
      def first
        @first ||= FFI::MemoryPointer.new(:pointer)
      end

      # Return a pointer to the last form element in libcurl.
      #
      # @example Return the last form element.
      #   form.last
      #
      # @return [ FFI::Pointer ] The last element.
      def last
        @last ||= FFI::MemoryPointer.new(:pointer)
      end

      # Return if form is multipart. The form is multipart
      # when it contains a file or multipart option is set on the form during creation.
      #
      # @example Return if form is multipart.
      #   form.multipart?
      #
      # @return [ Boolean ] True if form is multipart, else false.
      def multipart?
        return true if @multipart
        contains_file?(@params)
      end

      # Add form elements to libcurl.
      #
      # @example Add form to libcurl.
      #   form.materialize
      def materialize
        unless Curl.respond_to?(:formadd)
          raise NotImplementedError,
            "curl_formadd is not supported by this libcurl; use the MIME API instead"
        end

        ensure_named_fields!
        query_pairs.each { |pair| form_add(pair.first.to_s, pair.last) }
      end

      # Build a MIME structure for this form.
      #
      # @example Build a MIME structure.
      #   form.mime
      #
      # @return [ Ethon::Curl::Mime ] The MIME structure.
      def mime
        @mime ||= begin
          ensure_named_fields!
          structure = Ethon::Curl::Mime.new(@easy)
          query_pairs.each do |pair|
            part = structure.addpart
            name, content = pair
            part.name = name.to_s
            if content.is_a?(Array)
              part.file = content[2]
              part.filename = content[0]
              part.type = content[1]
            else
              part.data = content.to_s
            end
          end
          structure
        end
      end

      private

      # A multipart part needs a field name. A raw String body is one pair and
      # has no name, which used to produce an unnamed part through the MIME API
      # and a NoMethodError through the form API.
      def ensure_named_fields!
        return unless query_pairs.any? { |pair| pair.is_a?(String) }

        raise ArgumentError, "multipart bodies require a Hash of fields"
      end

      def contains_file?(value)
        case value
        when Hash
          value.values.any? { |item| contains_file?(item) }
        when Array
          value.any? { |item| contains_file?(item) }
        else
          value.is_a?(File) || (defined?(Tempfile) && value.is_a?(Tempfile))
        end
      end

      def form_add(name, content)
        name = validate_header_line(:name, name.to_s)
        code = case content
        when Array
          # The form API writes these into Content-Disposition headers. Older
          # libcurl versions do not escape them.
          filename = validate_header_line(:filename, content[0].to_s)
          content_type = validate_header_line(:content_type, content[1].to_s)
          Curl.formadd(first, last,
                       :form_option, :copyname, :pointer, name,
                       :form_option, :namelength, :long, name.bytesize,
                       :form_option, :file, :string, content[2],
                       :form_option, :filename, :string, filename,
                       :form_option, :contenttype, :string, content_type,
                       :form_option, :end
                      )
        else
          Curl.formadd(first, last,
                       :form_option, :copyname, :pointer, name,
                       :form_option, :namelength, :long, name.bytesize,
                       :form_option, :copycontents, :pointer, content.to_s,
                       :form_option, :contentslength, :long, content ? content.to_s.bytesize : 0,
                       :form_option, :end
                      )
        end

        raise Errors::FormAdd.new(code) unless code == 0

        setup_garbage_collection
      end

      def setup_garbage_collection
        # first is a pointer to a pointer. Since it's a MemoryPointer it will
        # auto clean itself up, but we need to clean up the object it points
        # to. So this results in (pseudo-c):
        #   form_data_cleanup_handler = *first
        #   curl_form_free(form_data_cleanup_handler)
        @form_data_cleanup_handler ||= Curl::FormData.new(@first.get_pointer(0))
      end
    end
  end
end
