# frozen_string_literal: true

module Transform
  class SearchString
    class Transformer

      def initialize(node)
        @node = node
        @klass = self.class
      end

      def term_transform(term_node)
        term_node.value
      end

      def tokens_transform(tokens_node)
        tokens_node.to_s
      end

      # @param phrase_node [SearchParser::Node::Phrase]
      def phrase_transform(phrase_node)
        %("#{value}")
      end

      # @param or_node [SearchParser::Node::Or]
      def or_transform(or_node)
        "(#{@klass.new(or_node.left).transform} OR #{@klass.new(or_node.right).transform})"
      end

      # @param and_node [SearchParser::Node::And]
      def and_transform(and_node)
        "(#{@klass.new(and_node.left).transform} AND #{@klass.new(and_node.right).transform})"
      end

      # @param not_node [SearchParser::Node::Not]
      def not_transform(not_node)
        "(NOT (#{@klass.new(not_node.value).transform})"
      end

      def search_transform(search_node)
        search_node.values.map { |child_node| @klass.new(child_node).transform }.join(" ")
      end

      # @param @search_node [SearchParser::Node]
      def transform
        node = @node
        case node
        when SearchParser::Node::Tokens
          tokens_transform(node)
        when SearchParser::Node::And
          and_transform(node)
        when SearchParser::Node::Or
          or_transform(node)
        when SearchParser::Node::Term
          term_transform(node)
        when SearchParser::Node::Phrase
          phrase_transform(node)
        when SearchParser::Node::Not
          not_transform(node)
        when SearchParser::Node::Search
          search_transform(node)
        end
      end
    end

  end
end
