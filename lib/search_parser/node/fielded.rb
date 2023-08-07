# frozen_string_literal: true

require "search_parser/node/generic"

module SearchParser::Node
  class Fielded < Generic
    attr_accessor :fieldname
    def initialize(fieldname, value)
      super(value)
      @fieldname = fieldname
    end

    def dup(f: fieldname, n: node)
      self.class.new(f, n.dup)
    end

    def shake
      dup(f: fieldname, n: value.dup.shake)
    end

    def to_s
      "#{fieldname}:(#{value})"
    end

    def inspect
      "<#{fieldname}: #{value.inspect}>"
    end

    def printable_tree_structure
      {fieldname => value.printable_tree_structure}
    end
  end
end
