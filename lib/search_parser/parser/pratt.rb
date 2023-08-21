# frozen_string_literal: true

require_relative "scanner"
require_relative "../node"

module SearchParse
  class Pratt
    def initialize(field_names:)
      @field_names = field_names
      @field_re = %r{(?<field>#{@field_names.join("|")}):(?!\s)}
    end

    def parse(str)
      tokens = SearchParser::Scanner.new(str).to_a.reject { |x| x == :space }
      tokens = collapse_terms(tokens)
    end

    def collapse_terms(tokens)
    end
  end
end
