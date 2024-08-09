# frozen_string_literal: true

module SearchParser
  module Lexer
    # It's just an array, but you can't push a nil. Just convenient
    class NoNilsStack < SimpleDelegator
      def initialize(arr = [])
        @tokens = arr
        __setobj__(@tokens)
      end

      def push(val)
        @tokens.push val unless val.nil?
        val
      end

      alias_method :<<, :push
      alias_method :add, :push
    end
  end
end
