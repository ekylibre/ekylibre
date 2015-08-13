module Nomen
  # An item of a nomenclature is the core data.
  class Item
    attr_reader :nomenclature, :left, :right, :depth, :aliases, :parent_name
    attr_accessor :name, :properties

    # New item
    def initialize(nomenclature, name, properties = {})
      @nomenclature = nomenclature
      @name = name.to_s
      @parent_name = properties.delete(:parent_name)
      @properties = {}.with_indifferent_access
      properties.each do |k, v|
        set(k, v)
      end
    end

    def root?
      !parent
    end

    def parent=(item)
      if item.nomenclature != nomenclature || item.parents.include?(self)
        fail 'Invalid parent'
      end
      @parent = item
      @parent_name = @parent.name
      @nomenclature.rebuild_tree!
    end

    # Changes parent without rebuilding
    def parent_name=(name)
      @parent = nil
      @parent_name = name
    end

    def rename(_new_name)
    end

    def parent?
      parent.present?
    end

    def parent
      @parent ||= @nomenclature.find(@parent_name)
    end

    def original_nomenclature_name
      return parent.name.to_sym unless root?
      nil
    end

    # Returns children recursively by default
    def children(recursively = true)
      if recursively
        return @children ||= nomenclature.list.select do |item|
          item != self && @left <= item.left && item.right <= @right
        end
      end
      nomenclature.list.select do |item|
        (item.parent == self)
      end
    end

    # Returns direct parents from the closest to the farthest
    def parents
      @parents ||= (parent.nil? ? [] : [parent] + parent.parents)
    end

    def self_and_children
      [self] + children
    end

    def self_and_parents
      [self] + parents
    end

    # Computes left/right value for nested set
    # Returns right index
    def rebuild_tree!(left = 0, depth = 0)
      @depth = depth
      @left = left
      @right = @left + 1
      children = self.children(false)
      for child in children
        @right = child.rebuild_tree!(@right, @depth + 1) + 1
      end
      @right
    end

    # Returns true if the given item name match the current item or its children
    def include?(other)
      if other.is_a?(Item)
        item = other
      else
        unless item = nomenclature.find(other)
          fail StandardError, "Cannot find item #{other.inspect} in #{nomenclature.name}"
        end
      end
      unless item.nomenclature == nomenclature
        fail StandardError, 'Invalid item'
      end
      puts [@left, item.left, item.right, @right].inspect
      (@left <= item.left && item.right <= @right)
    end

    # Return human name of item
    def human_name(options = {})
      "nomenclatures.#{nomenclature.name}.items.#{name}".t(options.merge(default: ["items.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize]))
    end
    alias_method :humanize, :human_name

    def human_notion_name(notion_name, options = {})
      "nomenclatures.#{nomenclature.name}.notions.#{notion_name}.#{name}".t(options.merge(default: ["labels.#{name}".to_sym]))
    end

    def <=>(other)
      nomenclature.name <=> other.nomenclature.name && name <=> other.name
    end

    def <(other)
      unless other = (other.is_a?(Item) ? other : nomenclature[other])
        fail StandardError, 'Invalid operand to compare'
      end
      # other.children.include?(self)
      (other.left < @left && @right < other.right)
    end

    def >(other)
      unless other = (other.is_a?(Item) ? other : nomenclature[other])
        fail StandardError, 'Invalid operand to compare'
      end
      # self.children.include?(other)
      (@left < other.left && other.right < @right)
   end

    def <=(other)
      unless other = (other.is_a?(Item) ? other : nomenclature[other])
        fail StandardError, 'Invalid operand to compare'
      end
      # other.self_and_children.include?(self)
      (other.left <= @left && @right <= other.right)
    end

    def >=(other)
      unless other = (other.is_a?(Item) ? other : nomenclature[other])
        fail StandardError, "Invalid operand to compare (#{other} not in #{nomenclature.name})"
      end
      # self.self_and_children.include?(other)
      (@left <= other.left && other.right <= @right)
    end

    def inspect
      "#{@nomenclature.name}-#{@name}"
    end

    def to_xml_attrs
      attrs = {}
      attrs[:name] = name
      attrs[:parent] = parent_name if self.parent?
      properties.each do |pname, pvalue|
        if p = nomenclature.properties[pname.to_s]
          if p.type == :decimal
            pvalue = pvalue.to_s.to_f
          elsif p.list?
            pvalue = pvalue.join(', ')
          end
        end
        attrs[pname] = pvalue.to_s
      end
      attrs
    end

    # Returns property value
    def property(name)
      property = @nomenclature.properties[name]
      value = @properties[name]
      if property
        if value.nil? && property.fallbacks
          for fallback in property.fallbacks
            value ||= @properties[fallback]
            break if value
          end
        end
        value ||= cast_property(name, property.default) if property.default
      end
      value
    end

    def selection(name)
      property = @nomenclature.properties[name]
      if property.list?
        return property(name).collect do |i|
          ["nomenclatures.#{@nomenclature.name}.item_lists.#{self.name}.#{name}.#{i}".t, i]
        end
      elsif property.nomenclature?
        return Nomen[property(name)].list.collect do |i|
          [i.human_name, i.name]
        end
      else
        fail StandardError, 'Cannot call selection for a non-list property'
      end
    end

    # Checks if item has property with given name
    def has_property?(name)
      !@nomenclature.properties[name].nil?
    end

    # Returns property descriptor
    def method_missing(method_name, *args)
      return property(method_name) if has_property?(method_name)
      super
    end

    def set(name, value)
      fail "Invalid property: #{name.inspect}" if [:name, :parent, :parent_name].include?(name.to_sym)
      # TODO: check format
      if property = nomenclature.properties[name]
        value ||= [] if property.list?
      end
      @properties[name] = value
    end

    private

    def cast_property(name, value)
      @nomenclature.cast_property(name, value)
    end
  end
end
