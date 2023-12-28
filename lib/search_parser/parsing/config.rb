# frozen_string_literal: true

module SearchParser::Parsing
  class Config
    attr_accessor :field_names

    def initialize(field_names:)
      @field_names = field_names
    end
  end
end
