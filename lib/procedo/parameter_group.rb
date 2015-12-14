require 'procedo/cardinality'
require 'procedo/parameter'

module Procedo
  # Parameter is
  class ParameterGroup
    attr_reader :nomenclature
    attr_accessor :name, :cardinality

    def initialize(nomenclature, name, options = {})
      @nomenclature = nomenclature
      @name = name.to_sym
      @cardinality = Cardinality.new(options[:cardinality] || '+')
      @items = {}.with_indifferent_access
    end

    # Returns all items of the group
    # If +recursively+ is true, it will retrieve all parameters of sub-groups too.
    def items(recursively = false)
      recursively ? all_items : @items.values
    end

    # Returns an item with its name
    def fetch(name)
      @items[name]
    end
    alias_method :[], :fetch

    def find(name, type = nil)
      browse_all do |i|
        return i if i.name.to_s == name
      end
      return nil
    end

    def position_of(item)
      index = 1
      browse_all do |i|
        return index if i == item
        index += 1
      end
      return nil
    end

    def groups
      @items.select{ |i| i.is_a?(Procedo::ParameterGroup) }
    end

    # Browse items in their order
    def each_item(&block)
      items.each(&block)
    end

    def add_parameter(name, type, options = {})
      item = Procedo::Parameter.new(self, name, type, options)
      @items[item.name] = item
    end

    def add_parameter_group(name, options = {})
      item = Procedo::ParameterGroup.new(self, name, options)
      @items[item.name] = item
    end

    protected

    def browse_all(&block)
      @items.each do |k, item|
        yield item
        if item.is_a?(ParameterGroup)
          item.browse_all(&block)
        end
      end
    end
    

    # Retrieve all (nested or not) Parameter objects in the group in the order
    # defined by default.
    def all_items
      list = []
      items.each do |item|
        if item.is_a?(ParameterGroup)
          list += item.all_items
        else
          list << item
        end
      end
      list
    end
  end
end
