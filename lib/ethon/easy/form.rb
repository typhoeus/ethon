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

      # Return if form is multipart. The form is multipart when the multipart
      # option is set, when it contains a file, or when a value is wrapped in a
      # Multipart::Part that carries a content type or a filename. A wrapped
      # plain value is encoded like an unwrapped one.
      #
      # @example Return if form is multipart.
      #   form.multipart?
      #
      # @return [ Boolean ] True if form is multipart, else false.
      def multipart?
        return true if @multipart
        contains_multipart_part?(@params)
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
            add_mime_part(part, content)
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

      def contains_multipart_part?(value)
        case value
        when Multipart::Part
          value.upload? || !value.content_type.nil?
        when Hash
          value.values.any? { |item| contains_multipart_part?(item) }
        when Array
          value.any? { |item| contains_multipart_part?(item) }
        else
          Multipart::Part.file?(value)
        end
      end

      def add_mime_part(part, content)
        case content
        when Multipart::Part
          add_mime_part_from_part(part, content)
        when Queryable::FileInfo
          part.file = content[2]
          part.filename = content[0]
          part.type = content[1]
        else
          part.data = content.to_s
        end
      end

      def add_mime_part_from_part(part, content)
        unless content.upload?
          part.data = content.value.to_s
          part.type = content.content_type unless content.content_type.nil?
          return
        end

        filename = part_filename(content)
        content_type = part_content_type(content, filename)

        if content.file?
          part.file = File.expand_path(content.value.path)
        else
          part.data = content.value.to_s
        end
        part.filename = filename
        part.type = content_type
      end

      def form_add(name, content)
        name = validate_header_line(:name, name.to_s)
        options = [
          :form_option, :copyname, :pointer, name,
          :form_option, :namelength, :long, name.bytesize
        ]

        case content
        when Multipart::Part
          add_form_options_for_part(options, content)
        when Queryable::FileInfo
          add_form_file_options(options, content[2], content[0], content[1])
        else
          data = content.to_s
          options.concat([
            :form_option, :copycontents, :pointer, data,
            :form_option, :contentslength, :long, data.bytesize
          ])
        end

        options << :form_option << :end
        code = Curl.formadd(first, last, *options)

        raise Errors::FormAdd.new(code) unless code == 0

        setup_garbage_collection
      end

      def add_form_options_for_part(options, content)
        unless content.upload?
          data = content.value.to_s
          options.concat([
            :form_option, :copycontents, :pointer, data,
            :form_option, :contentslength, :long, data.bytesize
          ])
          return if content.content_type.nil?

          content_type = validate_header_line(:content_type, content.content_type.to_s)
          options.concat([:form_option, :contenttype, :string, content_type])
          return
        end

        filename = part_filename(content)
        content_type = part_content_type(content, filename)

        if content.file?
          add_form_file_options(
            options,
            File.expand_path(content.value.path),
            filename,
            content_type
          )
        else
          add_form_buffer_options(options, content.value.to_s, filename, content_type)
        end
      end

      def part_filename(part)
        part.filename || File.basename(part.value.path)
      end

      def part_content_type(part, filename)
        part.content_type || mime_type(filename)
      end

      def add_form_file_options(options, path, filename, content_type)
        # The form API writes these into Content-Disposition headers. Older
        # libcurl versions do not escape them.
        filename = validate_header_line(:filename, filename.to_s)
        content_type = validate_header_line(:content_type, content_type.to_s)
        options.concat([
          :form_option, :file, :string, path,
          :form_option, :filename, :string, filename,
          :form_option, :contenttype, :string, content_type
        ])
      end

      def add_form_buffer_options(options, data, filename, content_type)
        filename = validate_header_line(:filename, filename.to_s)
        content_type = validate_header_line(:content_type, content_type.to_s)

        # CURLFORM_BUFFERPTR does not copy the data, so keep it alive until
        # libcurl has read the form during perform.
        (@form_buffers ||= []) << data

        options.concat([
          :form_option, :buffer, :string, filename,
          :form_option, :bufferptr, :pointer, data,
          :form_option, :bufferlength, :long, data.bytesize,
          :form_option, :contenttype, :string, content_type
        ])
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
