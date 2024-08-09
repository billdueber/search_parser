# frozen_string_literal: true

require "strscan"

module SearchParser
  Token = Struct.new(:type, :value, :start_pos, :fullmatch, keyword_init: true)

  class Scanner < StringScanner
    def grab(matchspec)
      matchspec.grab(self)
    end
  end

  class Lexer
    attr_accessor :allfields, :rfields, :afields, :scanner, :matchspecs

    def initialize(fields: [], range_fields: [])
      @fields = fields
      @rfields = range_fields
      @allfields = Set.new(@fields + @rfields)
      @scanner = Scanner.new("")
      @matchspecs = build_matchspecs!
    end

    def build_matchspecs!
      specs = {}
      Patterns.merge(ComboPatterns).each_pair do |type, pat|
        capture = if pat.named_captures.has_key?("value")
          "value"
        end
        specs[type] = MatchSpec.new(pat, type, capture: capture)
      end

      field_name_or = allfields.join("|")
      field_pat = /(?<value>#{field_name_or}):/
      specs[:field] = MatchSpec.new(field_pat, :field, capture: "value")

      # require 'pry'; binding.pry
      specs
    end

    # @param ms [String] name of the matchspec
    def match_rule?(name)
      matchspecs[name].match?(self)
    end

    def grab(rule)
      scanner.grab(matchspecs[rule.to_sym])
    end

    def eat(rule)
      scanner.skip(matchspecs[rule.to_sym].pattern)
    end

    def parse(str)
      scanner.string = str
      tokens = NoNilsStack.new

      until scanner.eos?
        eat(:spaces)
        next if tokens << grab(:phrase)
        next if tokens << grab(:field)
        next if tokens << grab(:op)
        next if tokens << grab(:lparen)
        next if tokens << grab(:rparen)
        next if tokens << grab(:term)
      end
      tokens
    end
  end
end


__END__

LPAREN = "("
RPAREN = ")"
SPACE = /\s+/
COLON = ":"
DQUOTE = '"'
STOPCHAR = Regexp.union(LPAREN, RPAREN, DQUOTE, "\s", /\Z/)

FIELDS = %w(title author).sort { |a, b| b.size <=> a.size }.join("|")
# FieldedStart = Regexp.union(*(FIELDS.map { |x| /(?<field>#{x}):/ }))
FieldedStart = /(?<field>#{FIELDS}):/
# WORD = /(?<word>[^#{STOPCHAR}]+)/
WORD = /(?<word>[^\(\)\s\"\Z]+)/
PHRASE = /"(?<phrase>[^"]+)"/
PREFIX = /(?<prefix>#{WORD})\*/

NOTOP = /\bNOT\b/
ANDOP = /\bAND\b/
OROP = /\bOR\b/

OP = Regexp.union(ANDOP, OROP, NOTOP)
EOKeywords = Regexp.union(STOPCHAR, OP, FieldedStart, /\Z/)

# What order to scan in? Want to get the most tightly bound stuff first,
# basically the same as the parser
# * phrase
# * prefix
# * FieldedStart
# * op
# * lparen
# * rparen

str = ' one AND "two three" AND @#ANDOR LIVES OR (four* title:five AND " title:(six))'

def check_and_grab(pat)
  if @s.match?(pat)
    @s.scan pat
    puts @s.matched + " -- #{@s.named_captures}"
    @s.matched
  else
    false
  end
end

@s = StringScanner.new(str)

until @s.eos?
  next if @s.scan(SPACE)
  next if check_and_grab(PHRASE)
  if @s.match?('"')
    newstr = str[0..(@s.pos - 1)] + str[(@s.pos + 1)..-1]
    puts "Error: mismatched double-quote. Removing and trying again"
    puts "Adjusted query: #{newstr}"
    @s.string = newstr
    next
  end
  next if check_and_grab(PREFIX)
  next if check_and_grab(FieldedStart)
  next if check_and_grab(OP)
  next if check_and_grab(LPAREN)
  next if check_and_grab(RPAREN)
  next if check_and_grab(WORD)
  break
end

if @s.eos?
  puts "DONE!"
else
  puts "ERROR at #{str[0..(@s.pos - 1)]}*#{str[@s.pos]}*#{str[(@s.pos + 1)..-1]}"
end
