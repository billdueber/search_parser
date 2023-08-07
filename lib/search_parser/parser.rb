# frozen_string_literal: true

require_relative "parser/config"
require_relative "node"

module SearchParser
  class Parser
    attr_reader :config, :errors, :warnings, :parser

    def initialize(config)
      @config = config
      @errors = []
      @warnings = []
      
    end
    
  end
end
