# frozen_string_literal: true

module Ethon
  # Multipart form data support.
  module Multipart
    # A single part of a multipart form body.
    #
    # Wrap a value to control the content type, and optionally the filename,
    # that Ethon sends for that field. Values that are not wrapped keep the
    # existing behaviour: files are detected with mime-types and plain values
    # have no content type.
    #
    # @example A JSON field.
    #   Ethon::Multipart::Part.new('{"a":1}', content_type: "application/json")
    #
    # @example A file with an explicit filename and content type.
    #   Ethon::Multipart::Part.new(
    #     File.open("photo.jpg"),
    #     filename: "avatar.png",
    #     content_type: "image/png"
    #   )
    #
    # @example An in-memory upload.
    #   Ethon::Multipart::Part.new(
    #     "file contents",
    #     filename: "notes.txt",
    #     content_type: "text/plain"
    #   )
    class Part
      # @return [ String, File, Tempfile ] The value sent for this field.
      attr_reader :value

      # @return [ String, nil ] The filename sent for an upload.
      attr_reader :filename

      # @return [ String, nil ] The content type sent for this part.
      attr_reader :content_type

      # Create a new multipart part.
      #
      # A value that responds to #read must be a File or Tempfile. Ethon
      # sends files by path; other IO objects have to be read by the caller.
      #
      # @param [ String, File, Tempfile ] value The value of the part.
      # @param [ String, nil ] filename The filename to send. Setting it turns
      #   a String value into a file part.
      # @param [ String, nil ] content_type The content type for this part.
      #
      # @raise [ ArgumentError ] If value is an IO that Ethon cannot upload.
      def initialize(value, filename: nil, content_type: nil)
        if value.respond_to?(:read) && !self.class.file?(value)
          raise ArgumentError,
            "multipart parts take a String or a File, not #{value.class}; read the IO first"
        end

        @value = value
        @filename = filename
        @content_type = content_type
      end

      # Return whether the value is a file Ethon can read by path.
      #
      # @return [ Boolean ] True for File and Tempfile values.
      def file?
        self.class.file?(value)
      end

      # Return whether this part is an upload rather than a regular field.
      # A filename turns in-memory data into an upload, matching curl's
      # "-F name=value;filename=..." behaviour.
      #
      # @return [ Boolean ] True when the part has a file or a filename.
      def upload?
        file? || !filename.nil?
      end

      # @api private
      def self.file?(value)
        value.is_a?(File) || (defined?(Tempfile) && value.is_a?(Tempfile))
      end

      # Return the value as a string, so a part can still be encoded like a
      # plain form value when a caller asks for a non-multipart body.
      #
      # @return [ String ] The string representation of the value.
      def to_s
        value.to_s
      end

      def ==(other)
        other.is_a?(Part) &&
          value_key == other.value_key &&
          filename == other.filename &&
          content_type == other.content_type
      end
      alias eql? ==

      def hash
        [Part, value_key, filename, content_type].hash
      end

      # The value used by #== and #hash. Files compare by path because File
      # itself compares by identity.
      #
      # @api private
      def value_key
        file? ? value.path : value
      end

      def inspect
        "#<#{self.class} value=#{value.inspect} filename=#{filename.inspect} content_type=#{content_type.inspect}>"
      end
    end
  end
end
