# frozen_string_literal: true

module SearchParser
  module Lexer
    class MatchSpec
      attr_accessor :pattern, :capture, :type

      # @param pattern [Regexp, String]
      # @param type [Symbol]
      # @param capture [String, nil]
      def initialize(pattern, type, capture: nil)
        @pattern = if pattern.is_a? String
          Regexp.new(pattern)
        else
          pattern
        end
        @capture = capture
        @type = type
      end

      def match?(scanner)
        scanner.match?(pattern)
      end

      # @param scanner [StringScanner]
      def grab(scanner)
        startpos = scanner.pos
        if scanner.match?(pattern)
          scanner.scan(pattern)
          value = if capture
            scanner.named_captures[capture.to_s]
          else
            scanner.matched
          end
          Token.new(type: @type, value: value, fullmatch: scanner.matched, start_pos: startpos)
        end
      end
    end
  end
end
