# frozen_string_literal: true
module Ethon
  class Easy

    # This module contains the logic and knowledge about the
    # available options on easy.
    module Options
      CALLBACK_TYPES = [:callback, :debug_callback, :progress_callback].freeze

      attr_reader :url

      def url=(value)
        @url = value
        Curl.set_option(:url, value, handle)
      end

      def escape=( b )
        @escape = b
      end

      def escape?
        return true if !defined?(@escape) || @escape.nil?
        @escape
      end

      def multipart=(b)
        @multipart = b
      end

      def multipart?
        !!@multipart
      end

      def multipart_form=(form)
        self.httppost = form ? form.first.read_pointer : nil
        @multipart_form = form
      end

      Curl.easy_options(nil).each do |opt, props|
        method_name = "#{opt}=".freeze
        unless method_defined? method_name
          if CALLBACK_TYPES.include?(props[:type])
            define_method(method_name) do |value|
              Curl.set_option(opt, value, handle)
              retain_callback(opt, value)
              value
            end
          else
            define_method(method_name) do |value|
              Curl.set_option(opt, value, handle)
              value
            end
          end
        end
        next if props[:type] != :callback || method_defined?(opt)
        define_method(opt) do |&block|
          send(method_name, block)
          nil
        end
      end

      private

      def initialize_copy(other)
        super
        @procs = @procs.dup if @procs
      end

      def retain_callback(option, callback)
        if callback.nil?
          @procs.delete(option) if @procs
        else
          (@procs ||= {})[option] = callback
        end
      end
    end
  end
end
