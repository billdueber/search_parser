# frozen_string_literal: true

require "search_parser/node/multiclause"

module SearchParser::Node
  class Search < MultiClause
    def shake
      dup(values.map { |x| x.shake })
    end

    def to_s(top: false)
      if values.size == 1
        values.first.to_s(top: true)
      else
        values.join(" ")
      end
    end

    def testable
      if values.size == 1
        {search: values.first.testable}
      else
        {search: values.map(&:testable)}
      end
    end
  end
end
