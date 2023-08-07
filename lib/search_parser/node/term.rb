# frozen_string_literal: true

require_relative "generic"

module SearchParser::Node
  class Term < Generic
    def initialize(value)
      @value = value
    end

    def to_s
      value.to_s
    end
  end
end
