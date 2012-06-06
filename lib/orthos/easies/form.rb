require 'orthos/easies/util'

module Orthos
  module Easies
    class Form
      include Orthos::Easies::Util
      attr_accessor :escape

      def initialize(params)
        @params = params || {}
        ObjectSpace.define_finalizer(self, self.class.finalizer(self))
      end

      def self.finalizer(params)
        proc { Curl.formfree(params.first) if params.multipart? }
      end

      def first
        @first ||= FFI::MemoryPointer.new(:pointer)
      end

      def last
        @last ||= FFI::MemoryPointer.new(:pointer)
      end

      def multipart?
        query_pairs.any?{|pair| [File, Tempfile].include?(pair.last.class) }
      end

      def query_pairs
        @query_pairs ||= build_query_pairs_from_hash(@params, escape)
      end

      def empty?
        @params.empty?
      end

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
