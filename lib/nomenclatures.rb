module Nomenclatures

  XMLNS = "http://www.ekylibre.org/XML/2013/nomenclatures".freeze

  # This class represent a nomenclature
  class Nomenclature

    attr_reader :items, :namespace

    def initialize(element)
      name = element.attr("name").to_s.split(':')
      if name.size == 2
        @namespace = name.shift.to_sym
      elsif name.size != 1
        raise ArgumentError.new("Bad name of nomenclature: #{element.attr("name").to_s.inspect}")
      end
      @name = name.shift.to_sym
      @items = element.xpath("xmlns:items/xmlns:item").inject({}) do |hash, item|
        hash[item.attr("name").to_s] = Item.new(self, item)
        hash
      end
    end

    # Returns all items recursively
    def children
      @children ||= @items.values.inject({}) do |hash, item|
        hash[item.name] = item
        hash.merge(item.children) unless item.children.empty?
        hash
      end
    end

  end


  class Item
    attr_reader :nomenclature, :name, :tags, :attributes, :children, :namespace
    # New item
    def initialize(nomenclature, element)
      @nomenclature = nomenclature
      @name = element.attr("name")
      @child_nomenclature = element.attr("nomenclature")
      @namespace = nomenclature.namespace
      @tags = element.attr("tags").to_s.strip.split(/[\s\,]+/)
      @attributes = element.xpath('xmlns:attribute').inject({}) do |hash, attribute|
        hash[attribute.attr("name").to_s] = attribute.attr("value").to_s
        hash
      end
    end

    # Returns hash of children
    def children
      if n = Nomenclatures[child_nomenclature_name]
        n.children
      else
        return {}
      end
    end

    def child_nomenclature_name
      if @child_nomenclature
        if @child_nomenclature.to_s.split(':').size == 2
          return @child_nomenclature
        else
          return full_name
        end
      else
        return full_name
      end
    end

    def full_name
      namespace.to_s + ":" + name.to_s
    end
  end

  @@list = {}

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
      for path in Dir.glob(root.join("*.xml"))
        f = File.open(path, "rb")
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XMLNS
          document.root.xpath('xmlns:nomenclature').each do |nomenclature|
            name = nomenclature.attr("name").to_s
            @@list[name] = Nomenclature.new(nomenclature)
          end
        else
          Rails.logger.info("File #{path} is not a nomenclature as defined by #{XMLNS}")
        end
      end
    end

    # Returns the root of the nomenclatures
    def root
      Rails.root.join("config", "nomenclatures")
    end

  end

  # Load all nomenclatures
  load
end


