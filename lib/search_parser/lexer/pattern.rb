# frozen_string_literal: true

module SearchParser
  module Lexer
    class Pattern
      attr_accessor :id, :regexp, :capture_name

      # @param id [Symbol] A unique identifier for the token(s) you want to match
      # @param regex [Regexp] A regexp that matches the token you want to consume
      # @param capture_name [:default, String] The name of the `regex`'s named-capture that
      #   can be used to get
      #   the value of the token (as opposed to everything that matched). The default
      #   is to use `value` if the passed regex has a named capture called "value"
      #   and the entire matched string if it doesn't. Explicitly passing `nil` will
      #   ignore any named capture called `value`.
      def initialize(id, regex, capture_name: :default)
        @id = id
        @regex = regex
        @capture_name = case capture_name
        when nil
          nil
        when :default
          if @regex.named_captures.has_key? "value"
            "value"
          end
        else
          capture_name
        end
      end
    end
  end
end
