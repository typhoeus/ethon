require 'ethon/easies/util'

module Ethon
  module Easies

    # This class represents a form and is used to send a payload in the
    # request body via POST/PUT.
    # It handles multipart forms, too.
    class Form
      include Ethon::Easies::Util
      attr_accessor :escape

      # Return a new Form.
      #
      # @example Return a new Form.
      #   Form.new({})
      #
      # @param [ Hash ] params The parameter to initialize the form with.
      #
      # @return [ Form ] A new Form.
      def initialize(params)
        @params = params || {}
        ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      end

      # Frees form in libcurl if necessary.
      #
      # @example Free the form
      #   Form.finalizer(form)
      #
      # @param [ Form ] form The form to free.
      def self.finalizer(form)
        proc { Curl.formfree(form.first) if form.multipart? }
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

      # Return if form is multipart. The form is multipart,
      # when it contains a file.
      #
      # @example Return if form is multipart.
      #   form.multipart?
      #
      # @return [ Boolean ] True if form is multipart, else false.
      def multipart?
        query_pairs.any?{|pair| pair.last.is_a?(Array)}
      end

      # Return the query pairs.
      #
      # @example Return the query pairs.
      #   form.query_pairs
      #
      # @return [ Array ] The query pairs.
      def query_pairs
        @query_pairs ||= build_query_pairs_from_hash(@params, escape)
      end

      # Return the string representation of the form. This makes only
      # sense when the form is not multipart.
      #
      # @example Return string representation.
      #   form.to_s
      #
      # @return [ String ] The string representation.
      def to_s
        query_pairs.map{|pair| pair.join("=")}.join('&')
      end

      # Return wether there are elements in the form or not.
      #
      # @example Return if form is empty.
      #   form.empty?
      #
      # @return [ Boolean ] True if form is empty, else false.
      def empty?
        @params.empty?
      end

      # Add form elements to libcurl.
      #
      # @example Add form to libcurl.
      #   form.materialize
      def materialize
        query_pairs.each { |pair| form_add(pair.first.to_s, pair.last) }
      end

      private

      def form_add(name, content)
        case content
        when Array
          Curl.formadd(first, last,
                       :form_option, :copyname, :pointer, name,
                       :form_option, :namelength, :long, name.bytesize,
                       :form_option, :file, :string, content[2],
                       :form_option, :filename, :string, content[0],
                       :form_option, :contenttype, :string, content[1],
                       :form_option, :end
                      )
        else
          Curl.formadd(first, last,
                       :form_option, :copyname, :pointer, name,
                       :form_option, :namelength, :long, name.bytesize,
                       :form_option, :copycontents, :pointer, content,
                       :form_option, :contentslength, :long, content.bytesize,
                       :form_option, :end
                      )
        end
      end
    end
  end
end
