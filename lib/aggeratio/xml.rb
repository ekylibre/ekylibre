module Aggeratio
  class XML < Base
    def initialize(aggregator)
      super(aggregator)
      @minimum_level = :api
    end

    def build
      # Build code
      code = parameter_initialization
      code << "builder = Nokogiri::XML::Builder.new do |xml|\n"
      code << build_element(@root).dig
      code << "end\n"
      code << "return builder.to_xml\n"
      code
    end

    def build_element(element)
      method_name = "build_#{element.name}".to_sym
      code = ''
      if respond_to?(method_name)
        code << conditionate(send(method_name, element), element)
      elsif element.name.to_s != 'comment'
        #Rails.logger.warn("Markup <#{element.name}> is unknown or not implemented")
        code << "# #{element.name}: not implemented\n"
      end
      code
    end

    def build_elements(elements)
      code = ''
      for element in elements
        next if %w[property title].include?(element.name.to_s)
        code << build_element(element)
      end
      code << "# No elements\n" if code.blank?
      code
    end

    def build_children_of(element)
      build_elements(element.children)
    end

    def build_sections(element)
      item  = element.attr('for')
      code  = "for #{item} in #{element.attr('in')}\n"
      code << build_elements(element.xpath('xmlns:variable')).dig
      code << build_properties_hash(element.xpath('*[self::xmlns:property or self::xmlns:title]'), var: 'attrs').dig
      code << "  xml.send('#{normalize_name(item)}', attrs) do\n"
      code << build_children_of(element).dig(2)
      code << "  end\n"
      code << "end\n"
      if element.has_attribute?('name')
        code = "xml.send('#{normalize_name(element)}') do\n" + code.dig + "end\n"
      end
      code
    end

    def build_section(element)
      name = element.attr('name').to_s
      code = ''
      code << build_elements(element.xpath('xmlns:variable'))
      code << build_properties_hash(element.xpath('*[self::xmlns:property or self::xmlns:title]'), var: 'attrs')
      code << "xml.send('#{normalize_name(name)}', attrs) do\n"
      code << build_elements(element.xpath('*[not(self::xmlns:variable)]')).dig
      code << "end\n"
      code
    end

    def build_matrix(element)
      item = element.attr('for')
      code = build_children_of(element)
      if element.has_attribute?('in')
        code = "for #{item} in #{element.attr('in')}\n" +
               build_elements(element.xpath('xmlns:variable')).dig +
               "  xml.send('#{normalize_name(item)}') do\n" +
               code.dig(2) +
               "  end\n" \
               "end\n"
      end
      if element.has_attribute?('name')
        code = "xml.send('#{normalize_name(element)}') do\n" + code.dig + "end\n"
      end
      code
    end

    def build_cell(element)
      "xml.send('#{normalize_name(element)}', #{xml_value_of(element)})\n"
    end

    def build_properties_hash(items, options = {})
      var = options[:var] || 'properties'
      code = "#{var} = {}\n"
      max = items.collect { |i| i.attr('name').size }.max
      items.collect do |item|
        code << conditionate(("#{var}['" + normalize_name(item) + "'] = ").ljust(max + 7 + var.size) + xml_value_of(item) + "\n", item)
      end
      code
    end

    def xml_value_of(*args)
      options = args.extract_options!
      element = args.shift
      value = value_of(element)
      type = (element.has_attribute?('type') ? element.attr('type').to_s : :string).to_s.tr('-', '_').to_sym
      code = if type == :date || type == :datetime
               "(#{value} ? #{value}.xmlschema : #{value})"
             else
               value
             end
      code
    end
  end
end
