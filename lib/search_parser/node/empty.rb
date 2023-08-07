# frozen_string_literal: true

require_relative "generic"

module SearchParser::Node
  class Empty < Generic
    def initialize(str)
      @value = str
    end

    def to_s
      "<empty>"
    end
  end
end
