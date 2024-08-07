# frozen_string_literal: true

require "tty-tree"
module SearchParser::Node
  class Generic
    include Comparable

    attr_accessor :value, :parent

    def initialize(value)
      @value = if value.is_a? String
        Tokens.new(Term.new(value))
      else
        value
      end
      @value.parent = self
    end

    def dup(v = value)
      self.class.new(v)
    end

    def <=>(other)
      de_parenthesize(to_s) <=> de_parenthesize(other.to_s)
    end

    def shake
      dup(value.shake)
    end

    def name
      self.class.to_s.split("::").last
    end

    def root?
      %w[ROOT SEARCH].include? name
    end

    def fielded?
      return false if root?
      return true if name == "FIELDED"
      parent.fielded?
    end

    def to_s(top: false)
      value.to_s
    end

    def inspect
      "<#{name}> #{value}"
    end

    def test_string
      to_s
    end

    def printable_tree_structure
      inspect
    end

    def print_tree
      puts TTY::Tree.new(printable_tree_structure).render
    end

    def de_parenthesize(str)
      m = /\A\((.*?)\)\Z/.match(str)
      if m
        m[1]
      else
        str
      end
    end
  end

  class GenericMulti < Generic
    alias_method :values, :value

    def initialize(values)
      @value = values.is_a?(Array) ? values.compact : [values]
      @value = @value.map do |v|
        if v.is_a? String
          Tokens.new(Term.new(v))
        else
          v
        end
      end
      @value.each { |n| n.parent = self }
    rescue
      "AAAAA"
    end

    def shake
      if values.size == 1
        values.first.shake
      else
        dup(values.map(&:shake))
      end
    end

    def to_s(top: false)
      if top
        values.join(" ")
      else
        "(" + values.join(" ") + ")"
      end
    end

    def inspect
      v = case values.size
      when 0
        "<empty>"
      when 1..5
        values.map(&:inspect).join(" | ")
      else
        values.take(5).map(&:inspect).join(" | ") + "...(#{values.size - 5} more)"
      end
      "<#{name}(#{v})>"
    end

    def testable
      {name.downcase.to_sym => values.map(&:testable)}
    end

    def printable_tree_structure
      {name => values.map(&:printable_tree_structure)}
    end
  end
end
