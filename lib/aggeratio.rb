module Aggeratio
  @@load_path = []

  mattr_accessor :load_path

  class InvalidDocument < StandardError
  end

  autoload :Aggregator,       'aggeratio/aggregator'
  autoload :Base,             'aggeratio/base'
  autoload :Parameter,        'aggeratio/parameter'
  autoload :XML,              'aggeratio/xml'
  autoload :DocumentFragment, 'aggeratio/document_fragment'
  # autoload :JSON, 'aggeratio/json'
  # autoload :CSV,  'aggeratio/csv'
  # autoload :XSD,  'aggeratio/xsd'

  XMLNS = 'http://www.ekylibre.org/XML/2013/aggregators'.freeze
  NS_SEPARATOR = '-'.freeze

  @@list = HashWithIndifferentAccess.new
  @@categories = HashWithIndifferentAccess.new

  class << self
    def each(&block)
      if block.arity == 2
        @@list.each(&block)
      else
        @@list.values.each(&block)
      end
    end

    # Returns the names of the aggregators
    def names
      @@list.keys
    end

    # Give access to named aggregators
    def [](name)
      @@list[name]
    end

    # Load all aggregator and build Aggregator children
    def load
      each_xml_aggregator do |element|
        aggregator = build(element)
        @@list[aggregator.aggregator_name] = aggregator
        cat = aggregator.category
        @@categories[cat] ||= []
        @@categories[cat] << aggregator.id unless @@categories[cat].include?(aggregator.id)
      end
      Rails.logger.info 'Loaded aggregators: ' + Aggeratio.names.to_sentence
      true
    end

    # Browse all aggregator elements in XML files
    def each_xml_aggregator(&_block)
      @@load_path.sort.each do |file_path|
        f = File.open(file_path, 'rb')
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # TODO: Add a better syntax check
        if document.root.namespace.href.to_s == XMLNS
          document.root.xpath('xmlns:aggregator').each do |element|
            yield clean(element)
          end
        else
          Rails.logger.info("File #{file_path} is not a aggregator as defined by #{XMLNS}")
        end
      end
    end

    def of_category(cat)
      (@@categories[cat] || []).collect { |a| Aggeratio[a] }
    end

    def clean(element)
      # Merge <within>s
      for within in element.xpath('//xmlns:within')
        name = within.attr('name')
        of = within.attr('of')
        of_type = within.attr('of-type')
        of ||= name
        for child in within.children
          unless child.has_attribute?('value')
            child['value'] = child.attr('name').to_s
          end
          if of.present?
            child['of'] = if child.has_attribute?('of')
                            of + '.' + child.attr('of').to_s
                          else
                            of
                          end
          end
          unless child.has_attribute?('of-type') || of_type.blank?
            child['of-type'] = of_type
          end
          if name
            child['name'] = (child.has_attribute?('name') ? name + '-' + child.attr('name').to_s : name)
          end
          within.add_previous_sibling(child)
        end
        within.remove
      end

      # Flatten <section> and <sections>
      for section in element.xpath('//*[self::xmlns:section or self::xmlns:sections]')
        of = section.attr('of')
        of_type = section.attr('of-type')
        section['if'] = of if section.name == 'section' && of.present?
        for child in section.children
          if of.present?
            child['of'] = if child.has_attribute?('of')
                            of + '.' + child.attr('of').to_s
                          else
                            of
                          end
          end
          unless child.has_attribute?('of-type') || of_type.blank?
            child['of-type'] = of_type
          end
        end
      end
      # element.to_xml.split(/\n/).each_with_index{|l,i| puts (i+1).to_s.rjust(4)+": "+l}
      element
    end

    def build(element)
      agg = Base.new(element)
      name = agg.name

      code = "class #{agg.class_name} < Aggregator\n"

      parameters = agg.parameters
      root = agg.root

      code << "  class << self\n"

      code << "    def parameters\n"
      code << '      [' + agg.parameters.collect do |parameter|
        "Parameter.new(#{parameter.name.inspect}, :#{parameter.type}, #{parameter.options.inspect}).freeze"
      end.join(', ') + "].freeze\n"
      code << "    end\n"

      code << "    def aggregator_name\n"
      code << "      '#{name}'\n"
      code << "    end\n"
      code << "    alias :id :aggregator_name\n"

      code << "    def category\n"
      code << "      '#{element.attr('category')}'\n"
      code << "    end\n"

      code << "  end\n"

      params = 'options'
      code << "  def initialize(#{params} = nil)\n"
      code << "    #{params} ||= {}\n"
      for p in parameters
        if p.record_list?
          # campaigns
          code << "    if #{params}['#{p.name}'].is_a?(String)\n"
          code << "      @#{p.name} = #{p.foreign_class.name}.where(:id => #{params}['#{p.name}'].to_s.split(/[\\,\\s]+/))\n"
          code << "    elsif #{params}['#{p.name}'].is_a?(Hash)\n"
          code << "      @#{p.name} = #{p.foreign_class.name}.where(:id => #{params}['#{p.name}'].select{|k,v| !v.to_i.zero?}.map(&:first))\n"
          code << "    elsif #{params}['#{p.name}'].is_a?(Array)\n"
          code << "      @#{p.name} = #{p.foreign_class.name}.where(:id => #{params}['#{p.name}'])\n"
          # # campaign_ids
          # name = p.name.singularize + "_ids"
          # code << "    elsif #{params}['#{name}']\n"
          # code << "      @#{p.name} = #{p.foreign_class.name}.where(:id => #{params}['#{name}'].to_s.split(/[\\,\\s]+/))\n"
          code << "    else\n"
          code << "      @#{p.name} = #{p.foreign_class.name}.#{p.default}\n"
          code << "    end\n"
        elsif p.record?
          # campaign
          code << "    if #{params}['#{p.name}']\n"
          code << "      @#{p.name} = #{p.foreign_class.name}.find(#{params}['#{p.name}'].to_i)\n"
          # # campaign_id
          # name = p.name + "_id"
          # code << "    elsif #{params}['#{name}']\n"
          # code << "      @#{p.name} = #{p.foreign_class.name}.find(#{params}['#{name}'].to_i)\n"
          code << "    else\n"
          code << "      @#{p.name} = #{p.foreign_class.name}.#{p.default}\n"
          code << "    end\n"
        elsif p.decimal?
          code << "    @#{p.name} = (#{params}['#{p.name}'] ? #{params}['#{name}'].to_f : #{p.default.to_f.inspect})\n"
        elsif p.integer?
          code << "    @#{p.name} = (#{params}['#{p.name}'] ? #{params}['#{name}'].to_i : #{p.default.to_i.inspect})\n"
        elsif p.date?
          code << "    @#{p.name} = (#{params}['#{p.name}'] || #{p.default.to_s.inspect}).to_date\n"
        else
          code << "    @#{p.name} = (#{params}['#{p.name}'] ? #{params}['#{name}'].to_s : #{p.default.inspect})\n"
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

      if true # Rails.env.development?
        f = Rails.root.join('tmp', 'code', 'aggregators', "#{agg.name}.rb")
        FileUtils.mkdir_p(f.dirname)
        File.write(f, code)
      end
      # code.split(/\n/).each_with_index{|l,i| puts (i+1).to_s.rjust(4)+": "+l}

      class_eval(code)

      "Aggeratio::#{agg.class_name}".constantize
    end
  end
end
