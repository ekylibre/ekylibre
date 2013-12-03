module Nomen

  # An item of a nomenclature is the core data.
  class Item
    attr_reader :nomenclature, :name, :attributes, :children, :parent

    # New item
    def initialize(nomenclature, element, options = {})
      @nomenclature = nomenclature
      @name = element.attr("name").to_s
      @parent = options[:parent]
      @attributes = element.attributes.inject(HashWithIndifferentAccess.new) do |h, pair|
        h[pair[0]] = cast_attribute(pair[0], pair[1].to_s)
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

    # Returns direct parents from the closest to the farest
    def parents
      return (self.parent.nil? ? [] : [self.parent] + self.parent.parents)
    end

    def self_and_children
      [self] + self.children
    end

    def self_and_parents
      [self] + self.parents
    end

    # Returns true if the given item name match the current item or its children
    def include?(name)
      name = name.to_s
      return self_and_children.detect do |item|
        item.name == name
      end
    end

    # Return human name of item
    def human_name
      "nomenclatures.#{nomenclature.name}.items.#{name}".t(:default => ["items.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize])
    end
    alias :humanize :human_name


    def inspect
      "#{@nomenclature.name}-#{@name}"
    end

    # Returns attribute value
    def attr(name)
      attribute = @nomenclature.attributes[name]
      value = @attributes[name]
      if value.nil? and attribute.fallbacks
        for fallback in attribute.fallbacks
          value ||= @attributes[fallback]
          break if value
        end
      end
      if attribute.default
        value ||= cast_attribute(name, attribute.default)
      end
      return value
    end

    # Checks if item has attribute with given name
    def has_attribute?(name)
      !@nomenclature.attributes[name].nil?
    end

    # Returns Attribute descriptor
    def method_missing(method_name)
      return attr(method_name) if has_attribute?(method_name)
      return super
    end

    private

    def cast_attribute(name, value)
      value = value.to_s
      if attribute = @nomenclature.attributes[name]
        if attribute.type == :choice
          if value =~ /\,/
            raise InvalidAttribute, "An attribute of choice type cannot contain commas"
          end
          value = value.strip.to_sym
        elsif attribute.type == :list
          value = value.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
        elsif attribute.type == :boolean
          value = (value == "true" ? true : value == "false" ? false : nil)
        elsif attribute.type == :decimal
          value = value.to_d
        elsif attribute.type == :integer
          value = value.to_i
        elsif attribute.type == :symbol
          unless value =~ /\A\w+\z/
            raise InvalidAttribute, "An attribute #{name} must contains a symbol. /[a-z0-9_]/ accepted. No spaces. Got #{value.inspect}"
          end
          value = value.to_sym
        end
      elsif name.to_s != "name" # the only system name
        raise ArgumentError, "Undefined attribute #{name} in #{@nomenclature.name}"
      end
      return value
    end

  end


end
