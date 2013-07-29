module Aggeratio

  XMLNS = "http://www.ekylibre.org/XML/2013/aggregators".freeze
  NS_SEPARATOR = "-"

  class Aggregator

    attr_accessor :name, :parameters

    def initialize(element)
      name = element.attr("name").to_s.split(NS_SEPARATOR)
      if name.size == 2
        @namespace = name.shift.to_sym
      elsif name.size != 1
        raise ArgumentError.new("Bad name of procedure: #{element.attr("name").to_s.inspect}")
      end
      @name = name.shift.to_s.to_sym
      
    end

    
    
  end

  @@list = HashWithIndifferentAccess.new
  
  class << self
    # Returns the names of the aggregators
    def names
      @@list.keys
    end

    # Give access to named aggregators
    def [](name)
      @@list[name]
    end

    # Load all files
    def load
      # Inventory aggregators
      for path in Dir.glob(root.join("*.xml")).sort
        f = File.open(path, "rb")
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XMLNS
          document.root.xpath('xmlns:aggregator').each do |element|
            # aggregator = Aggregator.new(element)
            # @@list[aggregator.name] = aggregator
            aggregator = build(element)
            @@list[aggregator.name] = aggregator
          end
        else
          Rails.logger.info("File #{path} is not a aggregator as defined by #{XMLNS}")
        end
      end
      return true
    end

    # Returns the root of the aggregators
    def root
      Rails.root.join("config", "aggregators")
    end


    def build(element)
      name = element.attr("name")

      code  = "class #{name.camelcase}\n"

      root = element.children[1]

      # Returns name
      code << "  def self.name\n"
      code << "    '#{name}'\n"
      code << "  end\n"

      code << "  def initialize()\n"
      code << "  end\n"

      code << "  def to_json\n"
      code << build_xml(root).gsub(/\^/, '    ')
      code << "  end\n"

      code << "  def to_xml\n"
      code << build_xml(root).gsub(/\^/, '    ')
      code << "  end\n"

      code << "  def to_html\n"
      code << "  end\n"

      code << "end\n"

      return "Aggeratio::#{name.camelcase}".constantize
    end


    def build_xml(root)
    end

  end

  # Load all aggregators
  load

  Rails.logger.info "Loaded aggregators: " + names.to_sentence

end
