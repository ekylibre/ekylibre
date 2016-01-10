module Procedo
  module Formula
    class << self
      def parse(text, options = {})
        @@parser ||= ::Procedo::Formula::Parser.new
        unless tree = @@parser.parse(text.to_s, options)
          fail ::Procedo::Formula::SyntaxError, @@parser
        end
        tree
      end

      # def clean_tree(root)
      #   return if root.elements.nil?
      #   root.elements.delete_if{ |node| node.class.name == "Treetop::Runtime::SyntaxNode" }
      #   root.elements.each{ |node| clean_tree(node) }
      # end
    end
  end
end
