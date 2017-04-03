# encoding: utf-8

module Ekylibre
  module Navigation
    autoload :DSL,  'ekylibre/navigation/dsl'
    autoload :Node, 'ekylibre/navigation/node'
    autoload :Page, 'ekylibre/navigation/page'
    autoload :Tree, 'ekylibre/navigation/tree'

    class ReverseImpossible < StandardError
    end

    class << self
      def config_file
        Rails.root.join('config', 'navigation.xml')
      end

      def load_file(file)
        # Parse XML file
        f = File.open(file)
        doc = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks
        end
        f.close

        @tree = Tree.load_file(file, :navigation, %i[part group item])
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
        @tree.reverse(controller, action)
      end

      # Returns the path (part, group, item) from an action
      def reverse!(controller, action)
        unless path = reverse(controller, action)
          raise ReverseImpossible, "Cannot reverse action #{controller}##{action}"
        end
        path
      end

      # Returns the name of the part corresponding to an URL
      def part_of(controller, action)
        if r = reverse(controller, action)
          return r[:part]
        end
        nil
      end

      # Returns the name of the group corresponding to an URL
      def group_of(controller, action)
        reverse(controller, action)[:group]
      end

      # Returns the name of the item corresponding to an URL
      def item_of(controller, action)
        reverse(controller, action)[:item]
      end

      # Returns the group hash corresponding to the current part
      def groups_of(controller, action)
        @tree[part_of(controller, action)] || {}
      end

      # Returns the group hash corresponding to the part
      def groups_in(part)
        @tree[part] || {}
      end

      # Returns a human name corresponding to the arguments
      # 1: part
      # 2: group
      # 3: item
      def human_name(*args)
        levels = [nil, :part, :group, :item]
        send("#{levels[args.count]}_human_name", *args)
      end

      # Returns the human name of a group
      def part_human_name(part)
        ::I18n.translate("menus.#{part}".to_sym, default: ["labels.menus.#{part}".to_sym, "labels.#{part}".to_sym])
      end

      # Returns the human name of a group
      def group_human_name(part, group)
        ::I18n.translate(('menus.' + [part, group].join('.')).to_sym, default: ["menus.#{group}".to_sym, "labels.menus.#{group}".to_sym, "labels.#{group}".to_sym])
      end

      # Returns the human name of an item
      def item_human_name(part, group, item)
        p = hash[part][group][item].first
        ::I18n.translate(('menus.' + [part, group, item].join('.')).to_sym, default: ["menus.#{item}".to_sym, "labels.menus.#{item}".to_sym, "actions.#{p[:controller][1..-1]}.#{p[:action]}".to_sym, "labels.#{item}".to_sym])
      end

      # Returns icon name
      def icon(*args)
        if node = @tree.get(*args)
          return node.icon
        end
        'question-sign'
      end
    end

    load_file(config_file)
  end
end
