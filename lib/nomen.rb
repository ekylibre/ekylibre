module Nomen
  XMLNS = "http://www.ekylibre.org/XML/2013/nomenclatures".freeze
  NS_SEPARATOR = "-"

  class MissingNomenclature < StandardError
  end

  class InvalidPropertyNature < StandardError
  end

  class InvalidProperty < StandardError
  end

  autoload :Nomenclature,        'nomen/nomenclature'
  autoload :Item,                'nomen/item'
  autoload :PropertyNature,      'nomen/property_nature'


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

    # Browse all nomenclatures
    def each(&block)
      if block.arity == 2
        @@list.each(&block)
      else
        @@list.values.each(&block)
      end
    end

    # Load all files
    def load
      sets = HashWithIndifferentAccess.new

      # Inventory nomenclatures and sub-nomenclatures
      for path in Dir.glob(root.join("**", "*.xml")).sort
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
          raise StandardError, "All nomenclatures must have a root nomenclature (See #{namespace})"
        end
      end

      # Merge and load nomenclature sets
      for name, nomenclatures in sets
        # Rails.logger.debug "Load set #{name}... " + nomenclatures.values.collect{|n| n.attr("name") }.to_sentence
        load_set(name, nomenclatures.values)
      end

      # Checks nomenclatures
      for nomenclature in @@list.values
        nomenclature.check!
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
        raise MissingNomenclature, "Nomenclature #{n} is missing. Availables are: #{names.to_sentence(locale: :eng)}"
      end
      return self[n]
    end

  end

end

Nomen.load
Rails.logger.info "Loaded nomenclatures: " + Nomen.names.to_sentence

