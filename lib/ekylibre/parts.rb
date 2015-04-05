# encoding: utf-8
module Ekylibre

  module Parts

    autoload :Node, 'ekylibre/parts/node'
    autoload :Page, 'ekylibre/parts/page'
    autoload :Tree, 'ekylibre/parts/tree'

    class ReverseImpossible < StandardError
    end

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
          unless node.type == :part
            raise "group must be in a part"
          end
        end
        unless child = node.index[name]
          child = Node.new(:group, name, options)
          node.add_child child
        end
        yield_in_node(child, &block)
      end

      def item(name, options = {}, &block)
        unless node = current_node
          unless node.type == :group
            raise "item must be in a group"
          end
        end
        unless child = node.index[name]
          child = Node.new(:item, name, options)
          node.add_child child
        end
        yield_in_node(child, &block)
      end

      def page(to, options = {}, &block)
        unless current_node
          raise "No part/group/item given"
        end
        current_node.add_page(to, options)
      end

      private

      def current_node
        @stack.first
      end

      def yield_in_node(node, &block)
        @stack ||= []
        @stack.insert(0, node)
        yield
        @stack.shift
      end

    end

    class << self

      def config_file
        Rails.root.join("config", "parts.xml")
      end

      def load_file(file)
        # Parse XML file
        f = File.open(file)
        doc = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks
        end
        f.close

        @tree = Tree.load_file(file, :parts, [:part, :group, :item])
      end

      def parts
        @tree.children
      end

      # Execute code with DSL
      def exec_dsl(&block)
        DSL.run!(@tree, &block)
      end

      # Returns the path (part, group, item) from an action
      def reverse(controller, action)
        return @tree.reverse(controller, action)
      end

      # Returns the path (part, group, item) from an action
      def reverse!(controller, action)
        unless path = self.reverse(controller, action)
          raise ReverseImpossible, "Cannot reverse action #{controller}##{action}"
        end
        return path
      end

      # Returns the name of the part corresponding to an URL
      def part_of(controller, action)
        if r = reverse(controller, action)
          return r[:part]
        end
        return nil
      end

      # Returns the name of the group corresponding to an URL
      def group_of(controller, action)
        return reverse(controller, action)[:group]
      end

      # Returns the name of the item corresponding to an URL
      def item_of(controller, action)
        return reverse(controller, action)[:item]
      end

      # Returns the group hash corresponding to the current part
      def groups_of(controller, action)
        return @tree[part_of(controller, action)] || {}
      end

      # Returns the group hash corresponding to the part
      def groups_in(part)
        return @tree[part] || {}
      end

      # Returns a human name corresponding to the arguments
      # 1: part
      # 2: group
      # 3: item
      def human_name(*args)
        levels = [nil, :part, :group, :item]
        return self.send("#{levels[args.count]}_human_name", *args)
      end

      # Returns the human name of a group
      def part_human_name(part)
        ::I18n.translate("menus.#{part}".to_sym, default: ["labels.menus.#{part}".to_sym, "labels.#{part}".to_sym])
      end

      # Returns the human name of a group
      def group_human_name(part, group)
        ::I18n.translate(("menus." + [part, group].join(".")).to_sym, default: ["menus.#{group}".to_sym, "labels.menus.#{group}".to_sym, "labels.#{group}".to_sym])
      end

      # Returns the human name of an item
      def item_human_name(part, group, item)
        p = hash[part][group][item].first
        ::I18n.translate(("menus." + [part, group, item].join(".")).to_sym, default: ["menus.#{item}".to_sym, "labels.menus.#{item}".to_sym, "actions.#{p[:controller][1..-1]}.#{p[:action]}".to_sym, "labels.#{item}".to_sym])
      end

      # Returns icon name
      def icon(*args)
        if node = @tree.get(*args)
          return node.icon
        end
        return "question-sign"
      end

    end

    load_file(config_file)


  end

end
