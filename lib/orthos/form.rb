require 'orthos/shortcuts/util'

module Orthos
  class Form
    include Orthos::Shortcuts::Util
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

    # TODO: escaped or not?? triggers memoization.
    def multipart?
      query_pairs.any?{|pair| [File, Tempfile].include?(pair.last.class) }
    end

    def query_pairs
      @query_pairs ||= build_query_pairs_from_hash(@params, escape)
    end

    def empty?
      @params.empty?
    end

    private


    # def process!
    #   # add params
    #   traversal[:params].each { |p| formadd_param(p[0], p[1]) }
    #   # add files
    #   traversal[:files].each { |file_args| formadd_file(*file_args) }
    # end


    # def formadd_param(name, contents)
    #   Curl.formadd(@first, @last,
    #     :form_option, :copyname, :pointer, name,
    #     :form_option, :namelength, :long, Utils.bytesize(name),
    #     :form_option, :copycontents, :pointer, contents,
    #     :form_option, :contentslength, :long, Utils.bytesize(contents),
    #     :form_option, :end)
    # end

    # def formadd_file(name, filename, contenttype, file)
    #   Curl.formadd(@first, @last,
    #     :form_option, :copyname, :pointer, name,
    #     :form_option, :namelength, :long, Utils.bytesize(name),
    #     :form_option, :file, :string, file,
    #     :form_option, :filename, :string, filename,
    #     :form_option, :contenttype, :string, contenttype,
    #     :form_option, :end)
    # end
  end
end
