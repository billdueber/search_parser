# frozen_string_literal: true

require "search_parser/node/generic"

module SearchParser::Node
  class Not < Generic
    def to_s(top: nil)
      if top
        "NOT #{value}"
      else
        "(NOT #{super})"
      end
    end
  end
end
