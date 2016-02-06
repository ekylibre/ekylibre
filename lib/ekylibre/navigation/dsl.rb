module Ekylibre
  module Navigation
    class DSL
      def self.run!(tree, &block)
        dsl = new(tree)
        dsl.instance_exec(&block)
        tree.rebuild_index!
      end

      def initialize(tree)
        @tree = tree
      end

      def part(name, options = {}, &block)
        unless child = @tree[name]
          child = Node.new(:part, name, options)
          @tree.add_child child
        end
        yield_in_node(child, &block)
      end

      def group(name, options = {}, &block)
        unless node = current_node
          raise 'group must be in a part' unless node.type == :part
        end
        unless child = node.index[name]
          child = Node.new(:group, name, options)
          node.add_child child
        end
        yield_in_node(child, &block)
      end

      def item(name, options = {}, &block)
        unless node = current_node
          raise 'item must be in a group' unless node.type == :group
        end
        unless child = node.index[name]
          child = Node.new(:item, name, options)
          node.add_child child
        end
        yield_in_node(child, &block)
      end

      def page(to, options = {}, &_block)
        raise 'No part/group/item given' unless current_node
        current_node.add_page(to, options)
      end

      private

      def current_node
        @stack.first
      end

      def yield_in_node(node, &_block)
        @stack ||= []
        @stack.insert(0, node)
        yield
        @stack.shift
      end
    end
  end
end
