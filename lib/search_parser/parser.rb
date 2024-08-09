# frozen_string_literal: true

require_relative "parsing/config"
require_relative "parsing/recursive_descent"
require_relative "node"

module SearchParser
  class Parser
    attr_reader :config, :errors, :warnings, :parser

    # @param config [Config]
    def initialize(config)
      @config = config
      @errors = []
      @warnings = []
      @parser = Parsing::RecursiveDescent.new(field_names: config.field_names)
    end

    def ppt(str)
      @parser.parse(str)
      @parser.parse(str)
    end

    def parse(str)
      @parser.parse(str)
    rescue SearchParser::Parsing::Error => e
      "Error: #{e.context.state}"
    end
  end
end
