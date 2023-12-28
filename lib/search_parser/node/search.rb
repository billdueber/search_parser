# frozen_string_literal: true

require "search_parser/node/multiclause"

module SearchParser::Node
  class Search < MultiClause
    def initialize(orig, values)
      super(values)
      @original = orig
    end

    def print_tree
      puts ""
      puts "As given:       #{@original}"
      puts "As interpreted: #{self}"
      super
    end

    def dup(original: @original, values: @values)
      self.class.new(original, values)
    end

    def shake
      dup(original: @original, values: values.map { |x| x.shake })
    end

    def to_s(top: false)
      if values.size == 1
        values.first.to_s(top: true)
      else
        values.join(" ")
      end
    end

    def printable_tree_structure
      size = if values.size > 1
        " (#{values.size} clauses)"
      else
        ""
      end
      {"#{name}#{size}" => values.map(&:printable_tree_structure)}
    end

    def testable
      if values.size == 1
        {search: values.first.testable}
      else
        {search: values.map(&:testable)}
      end
    end
  end
end
