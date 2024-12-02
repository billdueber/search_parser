# frozen_string_literal: true

module SearchParser
  module Parsing
    class Context < StringScanner
      attr_reader :stack

      def initialize(str)
        super
        @stack = []
      end

      def push(rule)
        @stack.push Marker.new(rule.to_sym, self)
      end

      def pop
        @stack.pop
      end

      # @param rule [Symbol]
      def in_a?(rule)
        @stack.include?(rule)
      end

      def state
        @stack.last
      end
    end
  end
end
