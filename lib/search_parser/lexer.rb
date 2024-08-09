# frozen_string_literal: true

require "strscan"
require "delegate"
require_relative "lexer/lexer_patterns"
require_relative "lexer/no_nils_stack"

module SearchParser
  module Lexer
    class Lexer < StringScanner
      def initialize(allfields: [], range_fields: [], patterns: LexerPatterns.new(searchable_field_names: allfields))
        @allfields = allfields
        @range_fields = range_fields
        @patterns = patterns
      end
    end

    def [](sym)
      @patterns[sym.to_sym]
    end

    def matches?(rule)
      raise ArgumentError, "No rule named ':#{rule}'" unless self[rule.to_sym]
      super(self[rule])
    end

    def consume(rule)
      nil unless match?(rule)
    end

    def tokenize(str)
      stack = NoNilsStack.new
    end

    # @param p [Pattern]
    def add_pattern(p)
      @patterns[p.id] = p
    end
  end
end
