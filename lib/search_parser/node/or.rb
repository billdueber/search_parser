# frozen_string_literal: true

require "search_parser/node/generic"

module SearchParser::Node
  class Or < GenericMulti
    def initialize(left, right)
      super([left, right])
    end

    def left
      @value.first
    end

    def right
      @value.last
    end

    def binary?
      true
    end

    def unary?
      false
    end

    def to_s(top: false)
      if top
        "#{left} #{name.upcase} #{right}"
      else
        "(#{left} #{name.upcase} #{right})"
      end
    end

    def dup(l: left, r: right)
      self.class.new(l, r)
    end

    def shake
      dup(l: left.shake, r: right.shake)
    end
  end
end
