require "strscan"

a = "first q blah \\q blah2 q rest"

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
NOT = "NOT"
AND = "AND"
OR = "OR"
OP = /(AND|OR|NOT)/

FIELDS = %w(title author)
FIELD = %r((?<field>title|author):(?!\s))
WORD = /[^\(\)\s]+/
STOPCHAR = /[\(\)\s]/
PHRASE = /"(?<phrase>[^"]+)"/

class EXPR
  attr_accessor :value

  def initialize(v)
    @value = v
  end
end

NOTNODE = Struct.new(:value)
ANDNODE = Struct.new(:left, :right)
ORNODE = Struct.new(:left, :right)
FIELDEDNODE = Struct.new(:field, :value)
PHRASENODE = Struct.new(:value)
KEYWORDS = Struct.new(:value)
# def parse(str)
#   scanner = StringScanner.new(str)
#   parse_expr(scanner)
# end
#
# def parse_expr(scanner)
#   scanner.skip SPACE
#   parse_not(scanner)
# end
#
def parse_not(scanner)
  scanner.skip SPACE
  if scanner.scan(NOT)
    NOTNODE.new(parse_expr(scanner))
  else
    parse_and(scanner)
  end
end

def parse_and(scanner)
  left = parse_or(scanner)
  scanner.skip SPACE
  if scanner.scan(AND)
    ANDNODE.new(left, parse_expr(scanner))
  else
    left
  end
end

def parse_or(scanner)
  left = parse_fielded(scanner)
  scanner.skip SPACE
  if scanner.scan(OR)
    scanner.skip(SPACE)
    ORNODE.new(left, parse_expr(scanner))
  else
    left
  end
end

def shallowify(exp)
  if exp.is_a? KEYWORDS and exp.value.is_a? Array and exp.value.size == 1 and exp.value.first.is_a? PHRASENODE
    return exp.value.first
  end
  return exp unless exp.is_a? EXPR
  if exp.value.is_a? Array and exp.value.size == 1
    shallowify(exp.value.first)
  elsif exp.value.is_a? Array
    exp
  else
    shallowify(exp.value)
  end
end

def parse(str)
  scanner = StringScanner.new(str)
  Node::MultiClause.new(collect_expressions(scanner)).shake
end

def collect_expressions(scanner)
  scanner.skip SPACE
  return [] if scanner.eos?
  e = parse_expr(scanner)
  return [] unless e
  collect_expressions(scanner).unshift(e)
end

def parse_expr(scanner)
  scanner.skip SPACE
  parse_not(scanner)
end


def parse_fielded(scanner)
  scanner.skip SPACE
  field_prefix = scanner.scan(FIELD)
  if !field_prefix
    parse_value(scanner)
  else
    FIELDEDNODE.new(scanner[:field], parse_expr(scanner))
  end
end

def parse_value(scanner)
  if scanner.skip(LPAREN)
    collect_expressions(scanner).tap do
      scanner.scan(RPAREN) or raise "Can't find the rparen"
    end
  else
    parse_terms(scanner)
  end
end

def collect_words(scanner)
  scanner.skip(SPACE)
  return [] if scanner.eos?
  return [] if scanner.check(FIELD)
  return [] if scanner.check(OP)
  w = if scanner.scan(PHRASE)
        PHRASENODE.new(scanner[:phrase])
      else
        scanner.scan(WORD)
      end
  return [] unless w
  collect_words(scanner).unshift(w)
end

def parse_terms(scanner)
  words = collect_words(scanner)
  if !words.empty?
    KEYWORDS.new(words)
  else
    # parse_atom(scanner)
    nil
  end
end
