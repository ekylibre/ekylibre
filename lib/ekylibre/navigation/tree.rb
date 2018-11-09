module Ekylibre
  module Navigation
    class Tree
      class << self
        def load_file(file, root, levels)
          # Parse XML file
          f = File.open(file)
          doc = Nokogiri::XML(f) do |config|
            config.strict.nonet.noblanks
          end
          f.close

          # Collect levels
          tree = Tree.new(levels)

          doc.xpath("/#{root}/#{levels.first}").each do |element|
            tree.add_child Node.browse_element(element, levels)
          end
          tree.rebuild_index!
          tree
        end
      end

      attr_reader :levels, :children, :index

      def initialize(levels)
        @levels = levels.map(&:to_sym)
        @children = []
        @reversions = {}
      end

      def [](value)
        @index[value]
      end

      def get(*keys)
        key = keys.shift
        return @index[key].get(keys) if keys.any?
        @index[key]
      end

      def add_child(node)
        unless node.type == levels.first
          raise "Invalid node type: #{node.type.inspect}. Expecting #{levels.first.inspect}"
        end
        @children << node
      end

      def insert_part_after(node, key)
        if node.type != levels.first
          raise "Invalid node type: #{node.type.inspect}. Expecting #{levels.first.inspect}"
        end

        searched_key = search_index(key)

        @children.insert(searched_key + 1, node)

        rebuild_index!
      end

      def rebuild_index!
        @index = {}.with_indifferent_access
        @reversions = {}.with_indifferent_access
        @children.each do |child|
          child.rebuild_index!
          @reversions.deep_merge! child.reversions
          @index[child.name] = child
        end
      end

      def reverse(controller, action)
        return @reversions[controller][action] if @reversions[controller]
        nil
      end

      def inspect
        "<#{self.class.name} #{levels.inspect}>"
      end

      def search_index(key)
        searched_node = get(key)

        children.index(searched_node)
      end
    end
  end
end
