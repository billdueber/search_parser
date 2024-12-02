# frozen_string_literal: true

module SearchParser
  module Parsing
    class Marker
      attr_reader :rule, :string, :pos

      def initialize(rule, context)
        @rule = rule
        @string = context.rest
        @pos = context.pos
      end

      def to_s
        "'#{rule}' at #{pos} (#{rest})"
      end

      def rest
        string[pos..]
      end

      def before
        string[0..(pos - 2)]
      end

      def after
        string[pos..]
      end

      def char
        string[pos - 1]
      end

      def marked_string(open_string = "*", close_string = "*")
        "#{before}#{open_string}#{char}#{close_string}#{after}"
      end
    end
  end
end
