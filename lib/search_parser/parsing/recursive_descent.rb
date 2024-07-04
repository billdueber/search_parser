# frozen_string_literal: true

require "strscan"
require_relative "../node"
require_relative "errors"

module SearchParser::Parsing
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
      string[0..(pos - 2)]
    end

    def after
      string[pos..-1]
    end

    def char
      string[pos - 1]
    end

    def marked_string(open_string = "*", close_string = "*")
      "#{before}#{open_string}#{char}#{close_string}#{after}"
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
  end

  class RecursiveDescent
    # expr = not_expr+
    # not_expr = and_expr | NOT and_expr
    # and_expr = or_expr | or_expr AND expr
    # or_expr = term | term OR expr
    # term = value | field colon value
    # fielded = field colon value
    # atom = word+ | phrase
    # value = atom | '(' expr ')'

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
      @valid_field_re = %r{(?<field>#{@field_names.join("|")}):(?!\s)}
    end

    def pt(str)
      parse(str).print_tree
    end

    def parse(str)
      context = Context.new(str)
      SearchParser::Node::Search.new(str, collect_expressions(context)).shake
    end

    def collect_expressions(context)
      context.skip SPACE
      return [] if context.eos?
      e = parse_expr(context)
      return [] unless e
      collect_expressions(context).unshift(e)
    end

    def parse_expr(context)
      context = contextify(context)
      context.skip SPACE
      SearchParser::Node::MultiClause.new(parse_or(context))
    end

    def parse_or(context)
      context = contextify(context)
      left = parse_and(context)
      context.skip SPACE
      if context.scan(OROP)
        context.push :or
        context.skip(SPACE)
        right = parse_or(context)
        # raise "No right in OR" unless right
        context.pop
        SearchParser::Node::Or.new(left, right)
      else
        left
      end
    end

    def parse_and(context)
      context = contextify(context)
      left = parse_not(context)
      context.skip SPACE
      if context.scan(ANDOP)
        context.push :and
        context.skip(SPACE)
        right = parse_and(context)
        context.pop
        SearchParser::Node::And.new(left, right)
      else
        left
      end
    end

    def parse_not(context)
      context = contextify(context)
      context.skip SPACE
      if context.scan(NOTOP)
        context.push :not
        n = SearchParser::Node::Not.new(parse_value(context))
        context.pop
        n
      else
        parse_fielded(context)
      end
    end

    def parse_fielded(context)
      context = contextify(context)
      context.skip SPACE
      field_prefix = context.scan(@valid_field_re)
      if !field_prefix
        parse_value(context)
      else
        context.push :fielded
        node = SearchParser::Node::Fielded.new(context[:field], parse_value(context))
        context.pop
        node
      end
    end

    def parse_value(context)
      context = contextify(context)
      if context.check(LPAREN)
        startpos = context.pos
        startrest = context.rest
        context.skip(LPAREN)
        context.push :paren
        e = parse_expr(context)
        context.scan(RPAREN) or raise "Can't find the rparen started at #{startpos} in '#{startrest}''"
        context.pop
        e
      else
        parse_terms(context)
      end
    end

    def parse_terms(context)
      context = contextify(context)
      words = collect_terms(context)
      if !words.empty?
        SearchParser::Node::Tokens.new(words)
      else
        raise SearchParser::Parsing::EOInput.new(context)
      end
    end

    def collect_terms(context)
      context = contextify(context)
      context.skip(SPACE)
      return [] if end_of_terms(context)
      w = if context.scan(PHRASE)
        SearchParser::Node::Phrase.new(context[:phrase])
      elsif context.scan(WORD)
        SearchParser::Node::Term.new(context[:word])
      end
      return [] unless w
      collect_terms(context).unshift(w)
    end

    def end_of_terms(context)
      context.eos? or context.check(@valid_field_re) or context.check(OP)
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
