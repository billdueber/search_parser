# frozen_string_literal: true

module SearchParser::Parsing
  class Warning < StandardError
  end

  class Error < StandardError
  end

  class EOInput < Error
    attr_accessor :context
    def initialize(context, message = "")
      super(message)
      @context = context
    end
  end
end
