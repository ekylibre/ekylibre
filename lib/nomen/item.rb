module Nomen

  # An item of a nomenclature is the core data.
  class Item
    attr_reader :nomenclature, :name, :properties, :children, :parent, :left, :right, :depth

    # New item
    def initialize(nomenclature, element, options = {})
      @nomenclature = nomenclature
      @name = element.attr("name").to_s
      @parent = options[:parent]
      @properties = element.attributes.inject(HashWithIndifferentAccess.new) do |h, pair|
        h[pair[0]] = cast_property(pair[0], pair[1].to_s)
        h
      end
    end

    def root?
      !self.parent
    end

    def original_nomenclature_name
      return self.parent.name.to_sym unless root?
      return nil
    end

    # Returns children recursively by default
    def children(recursively = true)
      @children ||= nomenclature.items.values.select do |item|
        (item.parent == self)
      end
      if recursively
        return @children + @children.map(&:children).flatten
      end
      return @children
    end

    # Returns direct parents from the closest to the farthest
    def parents
      return (self.parent.nil? ? [] : [self.parent] + self.parent.parents)
    end

    def self_and_children
      [self] + self.children
    end

    def self_and_parents
      [self] + self.parents
    end


    # Computes left/right value for nested set
    # Returns right index
    def rebuild_tree!(left = 0, depth = 0)
      @depth = depth
      @left = left
      @right = @left + 1
      # puts "  " * @depth + "#{self.name.to_s.red} (#{@left.to_s.green}-#{@right.to_s.green})"
      children = self.children(false)
      for child in children
        @right = child.rebuild_tree!(@right, @depth + 1) + 1
      end
      # puts "  " * @depth + "> #{@left.to_s.green}-#{@right.to_s.yellow}" if children.any?
      return @right
    end


    # Returns true if the given item name match the current item or its children
    def include?(other)
      other = nomenclature.items[other] unless other.is_a?(Item)
      unless other.nomenclature == self.nomenclature
        raise StandardError, "Invalid item"
      end
      return (@left <= other.left and other.right <= @right)
      # return self_and_children.detect do |item|
      #   item.name == other.name
      # end
    end

    # Return human name of item
    def human_name
      "nomenclatures.#{nomenclature.name}.items.#{name}".t(:default => ["items.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize])
    end
    alias :humanize :human_name

    def <=>(other)
      self.nomenclature.name <=> other.nomenclature.name and self.name <=> other.name
    end

    def <(other)
      unless other = (other.is_a?(Item) ? other : self.nomenclature[other])
        raise StandardError, "Invalid operand to compare"
      end
      # other.children.include?(self)
      return (other.left < @left and @right < other.right)
    end

    def >(other)
      unless other = (other.is_a?(Item) ? other : self.nomenclature[other])
        raise StandardError, "Invalid operand to compare"
      end
      # self.children.include?(other)
      return (@left < other.left and other.right < @right)
   end

    def <=(other)
      unless other = (other.is_a?(Item) ? other : self.nomenclature[other])
        raise StandardError, "Invalid operand to compare"
      end
      # other.self_and_children.include?(self)
      return (other.left <= @left and @right <= other.right)
    end

    def >=(other)
      unless other = (other.is_a?(Item) ? other : self.nomenclature[other])
        raise StandardError, "Invalid operand to compare"
      end
      # self.self_and_children.include?(other)
      return (@left <= other.left and other.right <= @right)
    end

    def inspect
      "#{@nomenclature.name}-#{@name}"
    end

    # Returns property value
    def property(name)
      property_nature = @nomenclature.property_natures[name]
      value = @properties[name]
      if value.nil? and property_nature.fallbacks
        for fallback in property_nature.fallbacks
          value ||= @properties[fallback]
          break if value
        end
      end

      if property_nature.default
        value ||= cast_property(name, property_nature.default)
      end
      return value
    end

    def selection(name)
      property_nature = @nomenclature.property_natures[name]
      if property_nature.type == :list
        return self.property(name).collect do |i|
          ["nomenclatures.#{@nomenclature.name}.item_lists.#{self.name}.#{name}.#{i}".t, i]
        end
      elsif property_nature.type == :nomenclature
        return Nomen[self.property(name)].list.collect do |i|
          [i.human_name, i.name]
        end
      else
        raise StandardError, "Cannot call selection for a non-list property_nature"
      end
    end


    # Checks if item has property with given name
    def has_property?(name)
      !@nomenclature.property_natures[name].nil?
    end

    # Returns property descriptor
    def method_missing(method_name, *args)
      return property(method_name) if has_property?(method_name)
      return super
    end

    private

    def cast_property(name, value)
      value = value.to_s
      if property_nature = @nomenclature.property_natures[name]
        if property_nature.type == :choice
          if value =~ /\,/
            raise InvalidPropertyNature, "A property nature of choice type cannot contain commas"
          end
          value = value.strip.to_sym
        elsif property_nature.type == :list
          value = value.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
        elsif property_nature.type == :boolean
          value = (value == "true" ? true : value == "false" ? false : nil)
        elsif property_nature.type == :decimal
          value = value.to_d
        elsif property_nature.type == :integer
          value = value.to_i
        elsif property_nature.type == :symbol
          unless value =~ /\A\w+\z/
            raise InvalidPropertyNature, "A property '#{name}' must contains a symbol. /[a-z0-9_]/ accepted. No spaces. Got #{value.inspect}"
          end
          value = value.to_sym
        end
      elsif !["name", "aliases"].include?(name.to_s)
        raise ArgumentError, "Undefined property '#{name}' in #{@nomenclature.name}"
      end
      return value
    end

  end


end
