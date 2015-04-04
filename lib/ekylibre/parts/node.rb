module Ekylibre
  module Parts

    class Node

      class << self

        def browse_element(element, levels)
          node = new(levels[0], element.attr("name").to_s.to_sym, icon: element.attr("icon"))
          element.xpath('page').each do |page|
            node.add_page(page.attr("to"), default: (page.attr("default").to_s == "true"))
          end
          element.xpath("#{levels[1]}").each do |item|
            node.add_child(browse_element(item, levels[1..-1]))
          end if levels[1]
          return node
        end

      end

      attr_reader :type, :name, :parent, :pages, :icon, :index, :children, :pages, :default_page

      def initialize(type, name, options = {})
        @type = type.to_sym
        @name = name.to_sym
        @icon = options[:icon] || @name
        @children = []
        @pages = []
        @default_page = nil
        @parent = nil
      end

      def add_child(node)
        node.instance_variable_set("@parent", self)
        @children << node
      end

      # Add page to node
      # An page can be attached only once by node level
      def add_page(to, options = {})
        page = (to.is_a?(Page) ? to : Page.new(to))
        @pages << page unless @pages.include?(page)
        if options[:default] or @pages.size == 1
          @default_page = page
        end
      end

      def get(*keys)
        key = keys.shift
        return @index[key].get(keys) if keys.any?
        return @index[key]
      end

      def rebuild_index!
        @index = {}.with_indifferent_access
        @children.each do |child|
          child.rebuild_index!
          @index[child.name] = child
          child.pages.each do |page|
            add_page(page) unless @pages.include?(page)
          end
        end
      end

      def reversions
        hash = {}.with_indifferent_access
        @children.each do |child|
          hash.deep_merge!(child.reversions)
        end
        @pages.each do |page|
          hash[page.controller] ||= {}.with_indifferent_access
          hash[page.controller][page.action] ||= {}
          hash[page.controller][page.action][@type] = self
        end
        return hash
      end

      def human_name

        "parts.#{@name}_#{@type}".t(default: ["parts.#{@name}".to_sym, "labels.#{@name}".to_sym, default_page.human_name])
      end


    end

  end
end
