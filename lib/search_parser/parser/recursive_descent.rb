# frozen_string_literal: true

require "strscan"
require_relative "../node"

module SearchParser
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

    def parse(str)
      scanner = StringScanner.new(str)
      Node::Search.new(collect_expressions(scanner)).shake
    end

    def collect_expressions(scanner)
      scanner.skip SPACE
      return [] if scanner.eos?
      e = parse_expr(scanner)
      return [] unless e
      collect_expressions(scanner).unshift(e)
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
        Node::Not.new(parse_expr(scanner))
      else
        parse_and(scanner)
      end
    end

    def parse_and(scanner)
      scanner = scannerify(scanner)
      left = parse_or(scanner)
      scanner.skip SPACE
      if scanner.scan(ANDOP)
        scanner.skip(SPACE)
        Node::And.new(left, parse_expr(scanner))
      else
        left
      end
    end

    def parse_or(scanner)
      scanner = scannerify(scanner)
      left = parse_fielded(scanner)
      scanner.skip SPACE
      if scanner.scan(OROP)
        scanner.skip(SPACE)
        Node::Or.new(left, parse_expr(scanner))
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
        Node::Fielded.new(scanner[:field], parse_expr(scanner))
      end
    end

    def parse_value(scanner)
      scanner = scannerify(scanner)
      if scanner.skip(LPAREN)
        parse_expr(scanner).tap do
          scanner.scan(RPAREN) or raise "Can't find the rparen"
        end
      else
        parse_terms(scanner)
      end
    end

    def parse_terms(scanner)
      scanner = scannerify(scanner)
      words = collect_terms(scanner)
      if !words.empty?
        Node::Tokens.new(words)
      else
        nil # TODO: Change to a real EOS type?
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
      when StringScanner
        scanner
      when String
        StringScanner.new(scanner)
      else
        raise "Need to pass in a StringScanner or String"
      end
    end
  end
end
