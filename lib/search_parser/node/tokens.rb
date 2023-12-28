# frozen_string_literal: true

require_relative "generic"

module SearchParser::Node
  class Tokens < GenericMulti
    def shake
      dup
    end

    def testable
      to_s
    end

    def to_s(top: :ignored)
      if values.size == 1
        values.first.to_s
      else
        "(#{values.join(" ")})"
      end
    end

    def printable_tree_structure
      {name => values.map(&:printable_tree_structure)}
    end
  end
end
