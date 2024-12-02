# frozen_string_literal: true

require_relative "search_parser/version"
require_relative "search_parser/parser"
require_relative "transform/search_string"

module SearchParser
  def self.new(...)
    SearchParser::Parser.new(...)
  end
end
