# frozen_string_literal: true

require "search_parser/node/generic"

module SearchParser::Node
  class Fielded < Generic
    attr_accessor :fieldname
    def initialize(fieldname, node)
      super(node)
      @fieldname = fieldname
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
