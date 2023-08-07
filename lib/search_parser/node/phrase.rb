# frozen_string_literal: true

require_relative "term"

module SearchParser::Node
  class Phrase < Term
    def to_s
      %("#{value}")
    end

    def name
      "Phrase"
    end

    def inspect
      %(<#{name} "#{value}">)
    end
  end
end
