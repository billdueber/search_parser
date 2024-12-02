# frozen_string_literal: true

require_relative "../search_parser"
require_relative "search_string/transformer"


module Transform
  class SearchString

    def initialize(parser)
      @parser = parser
    end

    def transform(str)
      klass = self.class
      tree = @parser.parse(str)
      klass::Transformer.new(tree).transform
    end
  end
end


