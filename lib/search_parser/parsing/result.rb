# frozen_string_literal: true

module SearchParser
  class Parser
    class Result
      attr_reader :original, :used, :warnings, :errors

      def initialize(original:, used:, warnings:, errors:)
        @original = original
        @used = used
        @warnings = warnings
        @errors = errors
      end
    end
  end
end
