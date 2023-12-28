# frozen_string_literal: true

require "strscan"
require_relative "../node"

module SearchParser
  class EOInput < RuntimeError; end

  class Marker
    attr_reader :rule, :string, :pos

    def initialize(rule, context)
      @rule = rule
      @string = context.string
      @pos = context.pos
    end

    def to_s
      "'#{rule}' at #{pos} (#{rest})"
    end

    def rest
      string[pos..-1]
    end

    def before
      string[0..(pos - 1)]
    end

    def after
      string[(pos + 1)..-1]
    end

    def char
      string[pos]
    end

    def marked_string
      "#{before}*#{char}*#{after}"
    end
  end

  class Context < StringScanner
    attr_reader :stack

    def initialize(str)
      super(str)
      @stack = []
    end

    def push(rule)
      @stack.push Marker.new(rule.to_sym, self)
    end

    def pop
      @stack.pop
    end

    def state
      @stack.last
    end

    def in_fielded?
      @stack.map(&:rule).include? :fielded
    end
  end

  class RecursiveDescentOrig
    LPAREN = "("
    RPAREN = ")"
    SPACE = /\s+/
    COLON = ":"
    DQUOTE = '"'

    WORD = /(?<word>[^()\s]+)/
    STOPCHAR = /[()\s]/
    PHRASE = /"(?<phrase>[^"]+)"/

    NOTOP = "NOT"
    ANDOP = "AND"
    OROP = "OR"
    OP = /(AND|OR|NOT)/

    def initialize(field_names:)
      @field_names = field_names
      @field_check = %r{(?<field>#{@field_names.join("|")}):[^\s]}
      @field_scan = %r{(?<field>#{@field_names.join("|")}):}
    end

    def pt(str)
      parse(str).print_tree
    end

    def parse(str)
      context = Context.new(str)
      Node::Search.new(str, collect_expressions(context)).shake
    rescue => e
      raise "Error at #{context.pos} near #{context.state.marked_string}"
    end

    def collect_expressions(context)
      context.skip SPACE
      expressions = []
      while e = parse_expr(context)
        expressions << e
        context.skip SPACE
      end
      expressions
    rescue EOTerm => e
      expressions
    end

    def parse_expressions(context)
      e = collect_expressions(context)
      Node::MultiClause.new(e)
    end

    def parse_expr(context)
      context = contextify(context)
      context.skip SPACE
      Node::MultiClause.new(parse_not(context))
    end

    def parse_fielded(context)
      context = contextify(context)
      context.skip SPACE
      if context.check(@field_check)
        context.push :fielded
        context.scan(@field_scan)
        node = Node::Fielded.new(context[:field], parse_value(context))
        context.pop
        node
      else
        parse_value(context)
      end
    end

    def parse_not(context)
      context = contextify(context)
      context.skip SPACE
      if context.scan(NOTOP)
        context.push :not
        n = Node::Not.new(parse_expr(context))
        context.pop
        n
      else
        parse_and(context)
      end
    end

    def parse_and(context)
      context = contextify(context)
      left = parse_or(context)
      context.skip SPACE
      if context.scan(ANDOP)
        context.push :and
        context.skip(SPACE)
        begin
          right = parse_expr(context)
        rescue
          puts "NO RIGHT IN AND"
          raise "No right in AND"
        end
        context.pop
        Node::And.new(left, right)
      else
        left
      end
    end

    def parse_or(context)
      context = contextify(context)
      left = parse_fielded(context)
      context.skip SPACE
      if context.scan(OROP)
        context.push :or
        context.skip(SPACE)
        right = parse_expr(context)
        raise "No right in OR" unless right
        context.pop
        Node::Or.new(left, right)
      else
        left
      end
    end

    def parse_value(context)
      context = contextify(context)
      if context.check(LPAREN)
        context.push :paren
        context.skip(LPAREN)
        e = parse_expressions(context)
        rp = context.scan(RPAREN)
        if rp
          context.pop
          e
        else
          raise "No paren at #{context.state}"
        end
      else
        parse_terms(context)
      end
    end

    class EOTerm < RuntimeError; end

    def parse_terms(context)
      context = contextify(context)
      raise "Error: unmatched double-quote at #{context.rest}" if context.check(DQUOTE)
      words = collect_terms(context)
      if !words.empty?
        Node::Tokens.new(words)
      else
        raise EOTerm.new
      end
    end

    def collect_terms(context)
      context.skip(SPACE)
      return [] if end_of_terms(context)
      w = if context.scan(PHRASE)
        Node::Phrase.new(context[:phrase])
      elsif context.scan(WORD)
        Node::Term.new(context[:word])
      end
      return [] unless w
      collect_terms(context).unshift(w)
    end

    def end_of_terms(context)
      context.eos? or context.check(@field_check) or context.check(OP)
    end

    private

    def contextify(context)
      case context
      when Context
        context
      when String
        Context.new(context)
      else
        raise "Need to pass in a Context or String"
      end
    end
  end
end
