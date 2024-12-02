# frozen_string_literal: true

require "strscan"

module SearchParser::Parsing
  class Scanner < StringScanner
    include Enumerable

    LPAREN = "("
    RPAREN = ")"
    SPACE = /\s+/
    COLON = ":"
    DQUOTE = '"'
    PHRASE = /"(?<phrase>[^"]+)"/
    STOPCHAR = /[()"\s]/
    TERM = /(?<term>[^():\s]+)/

    ANDCHECK = /AND[(\s]/
    ORCHECK = /OR[\s(]/
    NOTCHECK = /NOT[\s(]/

    FIELDNAME = /[\p{Alnum}\-_]+/
    FIELDCHECK = /#{FIELDNAME}:[^\s]/
    FIELDSCAN = /(?<field>#{FIELDNAME}):/

    OPS = [ANDCHECK, ORCHECK, NOTCHECK]

    def each
      return enum_for(:each) unless block_given?
      until eos?
        yield next_token
      end
    end

    Term = Struct.new(:value) do
      def to_s
        "T:#{value}"
      end
    end

    Phrase = Struct.new(:value) do
      def to_s
        "Phr:#{value}"
      end
    end

    Field = Struct.new(:value) do
      def to_s
        "F:#{value}"
      end
    end

    # In general, we'll just pass through the special characters.
    # We'll make an exception for "terms" (runs of letters/numbers without any
    # special characters in them) and return those as a single TERM, and
    # phrases, which will get returned as the whole phrase
    def next_token
      scan(/\p{Z}+/) && (return :space)
      scan(PHRASE) && (return Phrase.new(self[:phrase]))
      scan(LPAREN) && (return :lparen)
      scan(RPAREN) && (return :rparen)
      scan(DQUOTE) && (return :dquote)
      # scan(COLON) && (return :colon)
      if check(FIELDCHECK)
        scan(FIELDSCAN)
        return Field.new(self[:field]))
      end

      if check(TERM)
        scan(TERM)
        t = self[:term]
        if OPS.any? {|op| op.match?(t)}
          return t.downcase.to_sym
        else
          return Term.new(self[:term])
        end
      end

      # Otherwise, just return the character in question
      scan(/./)
    end
  end
end
