module Aggeratio

  autoload :Base,             'aggeratio/base'
  autoload :Parameter,        'aggeratio/parameter'
  autoload :XML,              'aggeratio/xml'
  autoload :DocumentFragment, 'aggeratio/document_fragment'
  # autoload :JSON, 'aggeratio/json'
  # autoload :CSV,  'aggeratio/csv'

  # autoload :XSD,  'aggeratio/xsd'

  XMLNS = "http://www.ekylibre.org/XML/2013/aggregators".freeze
  NS_SEPARATOR = "-"

  class Aggregator

    def to_xml(options = {})
      raise NotImplementedError.new
    end

    def to_json(options = {})
      raise NotImplementedError.new
    end

    def key
      # raise NotImplementedError.new
      return rand(1_000_000).to_s(36)
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
            @@list[aggregator.aggregator_name] = aggregator
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
      # Merge <within>s
      for within in element.xpath('//xmlns:within')
        name_prefix  = (within.has_attribute?('name')  ? within.attr('name').to_s  + '-' : nil)
        value_prefix = (within.has_attribute?('value') ? within.attr('value').to_s + '.' : name_prefix ? within.attr('name').to_s  + '.' : nil)
        for child in within.children
          if value_prefix
            child["value"] = value_prefix + (child.attr("value") || child.attr("name")).to_s
          end
          if name_prefix
            child["name"] = name_prefix + child.attr("name").to_s
          end
          # child.parent = within.parent
          within.add_previous_sibling(child)
        end
        within.remove
      end

      # element.to_xml.split(/\n/).each_with_index{|l,i| puts (i+1).to_s.rjust(4)+": "+l}

      # Codes!

      agg = Base.new(element)
      name = agg.name

      code  = "class #{agg.class_name} < Aggregator\n"

      parameters = agg.parameters
      root = agg.root

      code << "  def self.parameters\n"
      code << "    return " + parameters.values.inject({}) do |hash, p|
        hash[p.name] = {:type => p.type, :name => p.name}
        hash
      end.inspect + "\n"
      code << "  end\n"

      # Returns name
      code << "  def self.aggregator_name\n"
      code << "    '#{name}'\n"
      code << "  end\n"

      code << "  def aggregator_name\n"
      code << "    self.class.aggregator_name\n"
      code << "  end\n"

      v = "params"
      code << "  def initialize(#{v} = {})\n"
      for p in parameters.values
        if p.type == :record_list
          # campaigns
          code << "    if #{v}['#{p.name}']\n"
          code << "      @#{p.name} = #{p.class_name}.where(:id => #{v}['#{p.name}'].to_s.split(/[\\,\\s]+/))\n"
          # campaign_ids
          name = p.name.singularize + "_ids"
          code << "    elsif #{v}['#{name}']\n"
          code << "      @#{p.name} = #{p.class_name}.where(:id => #{v}['#{name}'].to_s.split(/[\\,\\s]+/))\n"
          code << "    else\n"
          code << "      @#{p.name} = #{p.class_name}.#{p.default}\n"
          code << "    end\n"
        elsif p.type == :record
          # campaign
          code << "    if #{v}['#{p.name}']\n"
          code << "      @#{p.name} = #{p.class_name}.find(#{v}['#{p.name}'].to_i)\n"
          # campaign_id
          name = p.name + "_id"
          code << "    elsif #{v}['#{name}']\n"
          code << "      @#{p.name} = #{p.class_name}.find(#{v}['#{name}'].to_i)\n"
          code << "    else\n"
          code << "      @#{p.name} = #{p.class_name}.#{p.default}\n"
          code << "    end\n"
        elsif p.type == :string
          code << "    @#{p.name} = (#{v}['#{name}'] ? #{v}['#{name}'].to_s : #{p.default.inspect})\n"
        elsif p.type == :decimal
          code << "    @#{p.name} = (#{v}['#{name}'] ? #{v}['#{name}'].to_f : #{p.default.to_f.inspect})\n"
        elsif p.type == :integer
          code << "    @#{p.name} = (#{v}['#{name}'] ? #{v}['#{name}'].to_i : #{p.default.to_i.inspect})\n"
        else
          code << "    # unknown type for #{p.name}\n"
        end
      end
      code << "  end\n"

      # code << "  def to_json\n"
      # code << JSON.new(element).build.gsub(/^/, '    ')
      # code << "  end\n"

      code << "  def to_xml(options = {})\n"
      code << XML.new(element).build.gsub(/^/, '    ')
      code << "  end\n"

      code << "  def to_html_fragment\n"
      code << DocumentFragment.new(element).build.gsub(/^/, '    ')
      code << "  end\n"

      code << "end\n"

      code.split(/\n/).each_with_index{|l,i| puts (i+1).to_s.rjust(4)+": "+l}

      class_eval(code)

      return "Aggeratio::#{agg.class_name}".constantize
    end

  end

  # Load all aggregators
  load

  Rails.logger.info "Loaded aggregators: " + names.to_sentence

end
