module Nomen
  # This class represents a set of nomenclature like the reference DB
  class NomenclatureSet
    attr_accessor :version

    def initialize
      @nomenclatures = {}.with_indifferent_access
      @version = 0
    end

    def self.load_file(file)
      set = new
      f = File.open(file, 'rb')
      document = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks.noent
      end
      f.close
      document.root.children.each do |nomenclature|
        set.harvest_nomenclature(nomenclature)
      end
      set.version = document.root['version'].to_i
      set
    end

    def nomenclature_names
      @nomenclatures.keys
    end

    def nomenclatures
      @nomenclatures.values
    end

    def [](name)
      @nomenclatures[name]
    end
    alias_method :find, :[]

    def exist?(name)
      @nomenclatures[name].present?
    end

    def each(&block)
      if block.arity == 2
        @nomenclatures.each(&block)
      else
        nomenclatures.each(&block)
      end
    end

    # Returns references between nomenclatures
    def references
      list = []
      each do |nomenclature|
        list += nomenclature.references
      end
      list
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.nomenclatures(xmlns: Nomen::XMLNS, version: @version) do
          @nomenclatures.values.sort.each do |nomenclature|
            xml.nomenclature(nomenclature.to_xml_attrs) do
              xml.properties do
                nomenclature.properties.values.sort { |a, b| a.name <=> b.name }.each do |property|
                  xml.property(property.to_xml_attrs)
                end
              end
              xml.items do
                nomenclature.items.values.sort { |a, b| a.name <=> b.name }.each do |item|
                  xml.item(item.to_xml_attrs)
                end
              end
            end
          end
        end
      end
      builder.to_xml
    end

    def harvest_nomenclature(element)
      n = Nomenclature.harvest(element, set: self)
      @nomenclatures[n.name] = n
    end

    def add_nomenclature(name, options = {})
      fail "Nomenclature #{name} already exists" if @nomenclatures[name]
      options[:set] = self
      @nomenclatures[name] = Nomenclature.new(name, options)
    end

    def move_nomenclature(old_name, new_name)
      unless @nomenclatures[old_name]
        fail "Nomenclature #{old_name} does not exist"
      end
      fail "Nomenclature #{new_name} already exists" if @nomenclatures[new_name]
      @nomenclatures[new_name] = @nomenclatures.delete(old_name)
      @nomenclatures[new_name]
    end

    def change_nomenclature(name, changes = {})
      nomenclature = find(name)
      nomenclature.update_attributes(changes)
      if changes[:name]
        nomenclature = move_nomenclature(name, changes[:name])
      end
      return nomenclature
    end

    def remove_nomenclature(name)
      # TODO: Check dependencies
      fail "Nomenclature #{name} does not exist" unless @nomenclatures[name]
      @nomenclatures.delete(name)
    end

    def add_property(nomenclature, name, type, options = {})
      unless n = @nomenclatures[nomenclature]
        fail "Nomenclature #{nomenclature} does not exist"
      end
      n.add_property(name, type, options)
    end

    # TODO
    # def change_property(nomenclature, name, changes = {})
    #   unless n = @nomenclatures[nomenclature]
    #     fail "Nomenclature #{nomenclature} does not exist"
    #   end
    #   n.rename_property(name, changes = {})
    # end

    # TODO
    # def remove_property(nomenclature, name, options = {})
    # end

    def add_item(nomenclature, name, properties = {})
      unless n = @nomenclatures[nomenclature]
        fail "Nomenclature #{nomenclature} does not exist"
      end
      n.add_item(name, properties)
    end

    def change_item(nomenclature, name, changes = {})
      unless n = @nomenclatures[nomenclature]
        fail "Nomenclature #{nomenclature} does not exist"
      end
      n.change_item(name, changes)
    end

    def merge_item(nomenclature, name, into)
      unless n = @nomenclatures[nomenclature]
        fail "Nomenclature #{nomenclature} does not exist"
      end
      n.merge_item(name, into)
    end

    def remove_item(nomenclature, name)
      unless n = @nomenclatures[nomenclature]
        fail "Nomenclature #{nomenclature} does not exist"
      end
      n.remove_item(name, into)
    end
  end
end
