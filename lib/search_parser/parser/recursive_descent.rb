# frozen_string_literal: true

require "strscan"
require_relative "../node"

module SearchParser
  class Context < StringScanner
    attr_reader :stack

    extend Forwardable

    def_delegators :@stack, :push, :pop
    def initialize(str)
      super(str)
      @stack = []
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
    # value = atom | '( expr )'

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
      @field_re = %r{(?<field>#{@field_names.join("|")}):(?!\s)}
    end

    def pt(str)
      parse(str).print_tree
    end

    def parse(str)
      scanner = Context.new(str)
      Node::Search.new(str, collect_expressions(scanner)).shake
    rescue => e
      raise "Error at #{scanner.rest} in #{scanner.pop}"
    end

    def collect_expressions(scanner)
      scanner.skip SPACE
      return [] if scanner.eos?
      e = parse_expr(scanner)
      puts "Got e of #{e}"
      return [] unless e
      collect_expressions(scanner).unshift(e)
    rescue EOTerm => e
      []
    end

    def parse_expressions(scanner)
      e = collect_expressions(scanner)
      Node::MultiClause.new(e)
    end

    def parse_expr(scanner)
      scanner = scannerify(scanner)
      scanner.skip SPACE
      Node::MultiClause.new(parse_not(scanner))
    end

    def parse_not(scanner)
      scanner = scannerify(scanner)
      scanner.skip SPACE
      if scanner.scan(NOTOP)
        scanner.push :not
        n = Node::Not.new(parse_expr(scanner))
        scanner.pop
        n
      else
        parse_and(scanner)
      end
    end

    def parse_and(scanner)
      scanner = scannerify(scanner)
      left = parse_or(scanner)
      scanner.skip SPACE
      if scanner.scan(ANDOP)
        scanner.stack.push :and
        scanner.skip(SPACE)
        right = parse_expr(scanner)
        raise "No right in AND" unless right
        scanner.pop
        Node::And.new(left, right)
      else
        left
      end
    end

    def parse_or(scanner)
      scanner = scannerify(scanner)
      left = parse_fielded(scanner)
      scanner.skip SPACE
      if scanner.scan(OROP)
        scanner.stack.push :or
        scanner.skip(SPACE)
        right = parse_expr(scanner)
        raise "No right in OR" unless right
        scanner.pop
        Node::Or.new(left, right)
      else
        left
      end
    end

    def parse_fielded(scanner)
      scanner = scannerify(scanner)
      scanner.skip SPACE
      field_prefix = scanner.scan(@field_re)
      if !field_prefix
        parse_value(scanner)
      else
        scanner.stack.push :fielded
        node = Node::Fielded.new(scanner[:field], parse_value(scanner))
        scanner.pop
        node
      end
    end

    def parse_value(scanner)
      scanner = scannerify(scanner)
      if scanner.check(LPAREN)
        startpos = scanner.pos
        startrest = scanner.rest
        scanner.skip(LPAREN)
        scanner.stack.push :paren
        e = parse_expressions(scanner).tap do
          scanner.scan(RPAREN) or raise "Can't find the rparen started at #{startpos} in '#{startrest}''"
        end
        scanner.stack.pop
        e
      else
        parse_terms(scanner)
      end
    end

    class EOTerm < RuntimeError; end

    def parse_terms(scanner)
      scanner = scannerify(scanner)
      raise "Error: unmatched double-quote at #{scanner.rest}" if scanner.check(DQUOTE)
      words = collect_terms(scanner)
      if !words.empty?
        Node::Tokens.new(words)
      else
        raise EOTerm.new
      end
    end

    def collect_terms(scanner)
      scanner.skip(SPACE)
      return [] if end_of_terms(scanner)
      w = if scanner.scan(PHRASE)
        Node::Phrase.new(scanner[:phrase])
      elsif scanner.scan(WORD)
        Node::Term.new(scanner[:word])
      end
      return [] unless w
      collect_terms(scanner).unshift(w)
    end

    def end_of_terms(scanner)
      scanner.eos? or scanner.check(@field_re) or scanner.check(OP)
    end

    private

    def scannerify(scanner)
      case scanner
      when Context
        scanner
      when String
        StringScanner.new(scanner)
      else
        raise "Need to pass in a Context or String"
      end
    end
  end
end
