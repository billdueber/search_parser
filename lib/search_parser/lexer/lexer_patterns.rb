# frozen_string_literal: true

require_relative "pattern"

module SearchParser
  module Lexer
    class LexerPatterns < SimpleDelegator
      BaseRegex = {
        spaces: /\s+/,
        lparen: /\(/,
        rparen: /\)/,
        notop: /\bNOT\b/,
        andop: /\bAND\b/,
        orop: /\bOR\b/,
        phrase: /"(?<value>[^"]+)"/,
        term: /(?<value>[^\(\)\s\"\Z]+)/
      }

      # Some combinations
      ComboRegex = {
        op: Regexp.union(BaseRegex[:notop], BaseRegex[:andop], BaseRegex[:orop]),
        binop: Regexp.union(BaseRegex[:andop], BaseRegex[:orop]),
        uop: BaseRegex[:notop]
      }

      DefaultRegex = BaseRegex.merge(ComboRegex)
      DefaultPatterns = DefaultRegex.map do |id, reg|
        Pattern.new(id, reg)
      end

      attr_reader :searchable_field_names

      # @param [Array<Pattern>] List of Pattern objects
      # @param [Array<String>] searchable_field_names  List of field names that
      #   can support a fielded search; need to be computed at runtime
      def initialize(patterns: DefaultPatterns, searchable_field_names: [])
        @patterns = patterns.each_with_object({}) { |p, h| h[p.id] = p }
        @searchable_field_names = searchable_field_names
        unless searchable_field_names.empty?
          @patterns[:field] = field_pat(@searchable_field_names)
        end
        super(@patterns)
      end

      # @param field_names [Array<String>] List of field names that support a fielded search
      # @return [Pattern] A Pattern object that will match a field token for those fields
      def field_pat(fields)
        field_name_or = fields.join("|")
        field_pat = /(?<value>#{field_name_or}):/
        Pattern.new(:field, field_pat, capture_name: "value")
      end
    end
  end
end
