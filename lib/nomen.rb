module Nomen

  class MissingNomenclature < StandardError
  end

  XMLNS = "http://www.ekylibre.org/XML/2013/nomenclatures".freeze
  NS_SEPARATOR = "-"

  # This class represent a nomenclature
  class Nomenclature

    attr_reader :items, :name

    def self.harvest(nomenclature_name, nomenclatures)
      sets = HashWithIndifferentAccess.new
      for nomenclature in nomenclatures
        namespace, name = nomenclature.attr("name").to_s.split(NS_SEPARATOR)[0..1]
        name = :root if name.blank?
        sets[name] = nomenclature
      end

      # Find root
      unless root = sets[:root]
        raise ArgumentError.new("Missing root nomenclature in set #{nomenclature_name}")
      end

      # Browse recursively nomenclatures and sub-nomenclatures
      n = Nomenclature.new(nomenclature_name)
      n.harvest(root, sets)
      return n
    end

    # Browse and harvest items recursively
    def harvest(nomenclature, sets, options = {})
      # puts "Harvest #{nomenclature.attr('name')}..."
      # Attributes
      attributes = options[:attributes] || HashWithIndifferentAccess.new
      for attribute in nomenclature.xpath('xmlns:attributes/xmlns:attribute')
        n = attribute.attr("name")
        attributes[n] = attribute.attributes.inject(HashWithIndifferentAccess.new) do |h, pair|
          h[pair[0]] = pair[1].to_s
          h
        end
      end
      # Items
      for item in nomenclature.xpath('xmlns:items/xmlns:item')
        i = self.add_item(item, :parent => options[:parent], :attributes => attributes)
        if sets[i.name]
          self.harvest(sets[i.name], sets, :parent => i, :attributes => attributes)
        end
      end
      return self
    end

    # Add an item to the nomenclature
    def add_item(element, options = {})
      i = Item.new(self, element, options)
      @items[i.name] = i
      return i
    end

    # Instanciate a new nomenclature
    def initialize(name)
      @name = name
      @items = HashWithIndifferentAccess.new
    end

    # Return human name
    def human_name
      "nomenclatures.#{nomenclature.name}.name".t(:default => ["labels.#{name}".to_sym, name.humanize])
    end

    # List all item names. Can filter on a given item name and its children
    def all(item_name = nil)
      if item_name
        @items[item_name].self_and_children.map(&:name)
      else
        return @items.keys.sort
      end
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

  end


  class Item
    attr_reader :nomenclature, :name, :attributes, :children, :parent

    # New item
    def initialize(nomenclature, element, options = {})
      @nomenclature = nomenclature
      @name = element.attr("name")
      @parent = options[:parent]
      @attributes = element.attributes.inject(HashWithIndifferentAccess.new) do |h, pair|
        h[pair[0]] = pair[1].to_s
        h
      end
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

    # Return human name of item
    def human_name
      "nomenclatures.#{nomenclature.name}.items.#{name}".t(:default => ["items.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize])
    end

  end

  @@list = HashWithIndifferentAccess.new

  class << self

    # Returns the names of the nomenclatures
    def names
      @@list.keys
    end

    # Give access to named nomenclatures
    def [](name)
      @@list[name]
    end

    # Load all files
    def load
      sets = HashWithIndifferentAccess.new

      # Inventory nomenclatures and sub-nomenclatures
      for path in Dir.glob(root.join("*.xml")).sort
        f = File.open(path, "rb")
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XMLNS
          document.root.xpath('xmlns:nomenclature').each do |nomenclature|
            namespace, name = nomenclature.attr("name").to_s.split(NS_SEPARATOR)[0..1]
            name = :root if name.blank?
            sets[namespace] ||= HashWithIndifferentAccess.new
            sets[namespace][name] = nomenclature
          end
        else
          Rails.logger.info("File #{path} is not a nomenclature as defined by #{XMLNS}")
        end
      end

      # Checks sets
      for namespace, nomenclatures in sets
        unless nomenclatures.keys.include?("root")
          raise StandardError.new("All nomenclatures must have a root nomenclature (See #{namespace})")
        end
      end

      # Merge and load nomenclature sets
      for name, nomenclatures in sets
        # puts "Load set #{name}... " + nomenclatures.values.collect{|n| n.attr("name") }.to_sentence
        load_set(name, nomenclatures.values)
      end

      return true
    end

    # Returns the root of the nomenclatures
    def root
      Rails.root.join("config", "nomenclatures")
    end

    # Load a set/namespace of nomenclatures
    def load_set(name, nomenclatures)
      n = Nomenclature.harvest(name, nomenclatures)
      @@list[n.name] = n
      return n
    end

    # Returns the matching nomenclature
    def const_missing(name)
      n = name.to_s.underscore.to_sym
      unless @@list.has_key?(n)
        raise MissingNomenclature.new("Nomenclature #{n} is missing.")
      end
      return self[n]
    end

  end

  # Load all nomenclatures
  load

  Rails.logger.info "Loaded nomenclatures: " + names.to_sentence

end


