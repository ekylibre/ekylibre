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
        # puts "Harvest #{nomenclature['name'].inspect}".yellow
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


    def to_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.nomenclatures(xmlns: Nomen::XMLNS) do
          @nomenclatures.values.sort{|a,b| a.name <=> b.name}.each do |nomenclature|
            xml.nomenclature(nomenclature.to_xml_attrs) do
              xml.properties do
                nomenclature.properties.values.sort{|a,b| a.name <=> b.name}.each do |property|
                  xml.property(property.to_xml_attrs)
                end
              end
              xml.items do
                nomenclature.items.values.sort{|a,b| a.name <=> b.name}.each do |item|
                  xml.item(item.to_xml_attrs)
                end
              end
            end
          end
        end
      end
      return builder.to_xml
    end

    def harvest_nomenclature(element)
      n = Nomenclature.harvest_nomenclature(element)
      @nomenclatures[n.name] = n
    end

    def add_nomenclature(name, options = {})
      if @nomenclatures[name]
        fail "Nomenclature #{name} already exists"
      end
      @nomenclatures[name] = Nomenclature.new(name, options)
    end

    def rename_nomenclature(old_name, new_name)
      unless @nomenclatures[old_name]
        fail "Nomenclature #{old_name} does not exist"
      end
      if @nomenclatures[new_name]
        fail "Nomenclature #{new_name} already exists"
      end
      @nomenclatures[new_name] = @nomenclatures.delete(old_name)
      @nomenclatures[new_name].name = new_name.to_s
      @nomenclatures[new_name]
    end

    def remove_nomenclature(name)
      # TODO Check dependencies
      unless @nomenclatures[name]
        fail "Nomenclature #{name} does not exist"
      end
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
      n.add_item(name, options)
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

    def write(file)
      puts "Write"
    end

  end

end
