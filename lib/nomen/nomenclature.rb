module Nomen

  # This class represent a nomenclature
  class Nomenclature

    attr_reader :property_natures, :items, :name, :roots

    # Instanciate a new nomenclature
    def initialize(name, translateable = true)
      @name = name.to_sym
      @items = HashWithIndifferentAccess.new
      @roots = []
      @property_natures = {}.with_indifferent_access
      @translateable = !!translateable
    end

    class << self

      def harvest(nomenclature_name, nomenclatures)
        sets = HashWithIndifferentAccess.new
        for nomenclature in nomenclatures
          namespace, name = nomenclature.attr("name").to_s.split(NS_SEPARATOR)[0..1]
          name = :root if name.blank?
          sets[name] = nomenclature
        end

        # Find root
        unless root = sets[:root]
          raise ArgumentError, "Missing root nomenclature in set #{nomenclature_name}"
        end

        # Browse recursively nomenclatures and sub-nomenclatures
        n = Nomenclature.new(nomenclature_name, !(root.attr("translateable").to_s == "false"))
        n.harvest(root, sets, root: true)
        n.rebuild_tree!
        return n
      end

    end

    # Browse and harvest items recursively
    def harvest(nomenclature, sets, options = {})
      for nature in nomenclature.xpath('xmlns:property-natures/xmlns:property-nature')
        add_property_nature(nature)
      end
      # Items
      for item in nomenclature.xpath('xmlns:items/xmlns:item')
        i = self.add_item(item, parent: options[:parent]) # , :property_natures => property_natures
        @roots << i if options[:root]
        if sets[i.name]
          self.harvest(sets[i.name], sets, :parent => i) # , :property_natures => property_natures
        end
      end
      return self
    end


    # Build a nested set index on items
    # Returns last right value
    def rebuild_tree!
      left = 0
      for item in roots
        left = item.rebuild_tree!(left) + 1
      end
      return left - 1
    end

    # Add an item to the nomenclature
    def add_item(element, options = {})
      i = Item.new(self, element, options)
      if @items[i.name]
        raise "Item #{i.name} is already defined in nomenclature #{self.name}"
      end
      @items[i.name] = i
      return i
    end

    # Add an property_nature to the nomenclature
    def add_property_nature(element, options = {})
      a = PropertyNature.new(self, element, options)
      @property_natures[a.name] = a
      return a
    end

    def check!
      # Check property_natures
      for property_nature in @property_natures.values
        if property_nature.choices_nomenclature and !property_nature.inline_choices? and !Nomen[property_nature.choices_nomenclature.to_s]
          raise InvalidPropertyNature, "[#{self.name}] #{property_nature.name} nomenclature property_nature must refer to an existing nomenclature. Got #{property_nature.choices_nomenclature.inspect}. Expecting: #{Nomen.names.inspect}"
        end
        if property_nature.type == :choice and property_nature.default
          unless property_nature.choices.include?(property_nature.default)
            raise InvalidPropertyNature, "The default choice #{property_nature.default.inspect} is invalid (in #{self.name}##{property_nature.name}). Pick one from #{property_nature.choices.sort.inspect}."
          end
        end
      end

      # Check items
      for item in list
        for property_nature in @property_natures.values
          choices = property_nature.choices
          if item.property(property_nature.name) and property_nature.type == :choice
            # Cleans for parametric reference
            name = item.property(property_nature.name).to_s.split(/\(/).first.to_sym
            unless choices.include?(name)
              raise InvalidProperty, "The given choice #{name.inspect} is invalid (in #{self.name}##{item.name}). Pick one from #{choices.sort.inspect}."
            end
          elsif item.property(property_nature.name) and property_nature.type == :list and property_nature.choices_nomenclature
            for name in item.property(property_nature.name) || []
              # Cleans for parametric reference
              name = name.to_s.split(/\(/).first.to_sym
              unless choices.include?(name)
                raise InvalidProperty, "The given choice #{name.inspect} is invalid (in #{self.name}##{item.name}). Pick one from #{choices.sort.inspect}."
              end
            end
          end
        end
      end

      # Default return
      return true
    end


    def translateable?
      @translateable
    end

    # Return human name
    def human_name
      "nomenclatures.#{nomenclature.name}.name".t(:default => ["labels.#{name}".to_sym, name.humanize])
    end
    alias :humanize :human_name

    # Returns the given item
    def [](item_name)
      @items[item_name]
    end

    # List all item names. Can filter on a given item name and its children
    def to_a(item_name = nil)
      if item_name
        return @items[item_name].self_and_children.map(&:name)
      else
        return @items.keys.sort
      end
    end
    alias :all :to_a

    # Returns a list for select as an array of pair (array)
    def selection(item_name = nil)
      items = (item_name ? @items[item_name].self_and_children : @items.values)
      return items.collect do |item|
        [item.human_name, item.name.to_s]
      end.sort do |a, b|
        a.first.lower_ascii <=> b.first.lower_ascii
      end
    end

    # Returns a list for select as an array of pair (hash)
    def selection_hash(item_name = nil)
      return @items[item_name].self_and_children.map do |item|
        {label: item.human_name, value: item.name}
      end.sort{|a,b| a[:label].lower_ascii <=> b[:label].lower_ascii }
    end

    # Returns a list for select, without specified items
    def select_without(already_imported)
      selection = @items.values.collect do |item|
        [item.human_name, item.name.to_s] unless already_imported[item.name.to_s]
      end
      selection.compact!
      selection.sort! do |a, b|
        a.first <=> b.first
      end
      selection
    end

    # Return first item name
    def first(item_name = nil)
      all(item_name).first
    end

    # Return the default item name
    def default(item_name = nil)
      first(item_name)
    end

    # Return the Item for the given name
    def find(item_name)
      return @items[item_name]
    end

    # Returns list of items as an Array
    def list
      return @items.values
    end

    # # Iterates on items
    # def each(&block)
    #   return list.each(&block)
    # end

    # List items with property_natures filtering
    def where(properties)
      @items.values.select do |item|
        valid = true
        for name, value in properties
          item_value = item.property(name)
          if value.is_a?(Array)
            one_found = false
            for val in value
              if val.is_a?(Nomen::Item)
                one_found = true if item_value == val.name.to_sym
              else
                one_found = true if item_value == val
              end
            end
            valid = false unless one_found
          elsif value.is_a?(Nomen::Item)
            valid = false unless item_value == value.name.to_sym
          else
            valid = false unless item_value == value
          end
        end
        valid
      end
    end

    def find_by(properties)
      items = where(properties)
      return nil unless items.any?
      return items.first
    end

    # Returns the best match on nomenclature properties
    def best_match(property_name, searched_item)
      items = []
      begin
        list.select do |item|
          if item.property(property_name) == searched_item.name
            items << item
          end
        end
        break if items.any?
        searched_item = searched_item.parent
      end while searched_item
      return items
    end

    # Returns property nature
    def method_missing(method_name, *args)
      return @property_natures[method_name] || super
    end

  end

end
