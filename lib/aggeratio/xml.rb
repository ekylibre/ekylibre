module Aggeratio
  class XML < Base

    def build
      # Build code
      code  = parameter_initialization
      code << "builder = Nokogiri::XML::Builder.new do |xml|\n"
      code << build_element(@root).gsub(/^/, '  ')
      code << "end\n"
      code << "puts builder.to_xml\n"
      code << "return builder.to_xml\n"
      return code
    end

    def build_element(element)
      method_name = "build_#{element.name}".to_sym
      code = "# "
      if respond_to?(method_name)
        code << "#{element.name}\n"
        code << send(method_name, element)
      else
        Rails.logger.warn("Markup <#{element.name}> is unknown or not implemented")
        code << "#{element.name}: not implemented\n"
      end
      return code
    end

    def build_elements(element)
      code = ""
      for element in element.children
        next if ["attribute", "title"].include?(element.name.to_s)
        code << build_element(element)
      end
      code << "# No elements\n" if code.blank?
      return code
    end

    def build_collection(element)
      items = element.attr("name").to_s
      item  = element.attr("for") || items.singularize
      code  = "xml.#{items}() do\n"
      code << "  for #{item} in #{element.attr("with") || items}\n"
      code << build_elements(element.xpath('xmlns:variable')).gsub(/^/, '    ')
      code << build_attributes_hash(element.xpath("*[self::xmlns:attribute or self::xmlns:title]"), item, :var => "attrs").gsub(/^/, '    ')
      code << "    xml.#{item}(attrs) do\n"

      # attributes  = element.xpath("*[self::xmlns:attribute or self::xmlns:title]")
      # code << "    xml.#{item}(" + attributes.collect do |attr|
      #   attr.attr('name').to_s.gsub('_', '-').inspect + " => #{item}." + attr.attr('name').to_s.gsub('-', '_')
      # end.join(", ") + ") do\n"
      code << build_elements(element).gsub(/^/, '      ')
      code << "    end\n"
      code << "  end\n"
      code << "end\n"
      return code
    end

    def build_section(element)
      name = element.attr("name").to_s
      code = ""
      code << "xml.#{name}() do\n"
      code << build_elements(element).gsub(/^/, '  ')
      code << "end\n"
      return code
    end

    def build_variable(element)
      "#{element.attr('name')} = #{element.attr('value')} rescue nil\n"
    end

    def build_table(element)
      items = element.attr("name").to_s
      item  = element.attr("for") || items.singularize
      code  = "xml.#{items}() do\n"
      code << "  for #{item} in #{element.attr("with") || items}\n"
      code << build_elements(element.xpath('xmlns:variable')).gsub(/^/, '    ')
      code << build_attributes_hash(element.xpath("xmlns:column"), item, :var => "attrs").gsub(/^/, '    ')
      code << "    xml.#{item}(attrs)\n"
      # code << build_elements(element).gsub(/^/, '      ')
      code << "  end\n"
      code << "end\n"
      return code
    end

    def build_attributes_hash(items, object, options = {})
      var = options[:var] || "attributes"
      code = "#{var} = {}\n"
      items.collect do |item|
        value = item.attr("value") || ("#{object}." + item.attr('name').to_s.gsub('-', '_'))
        code << ("#{var}['" + item.attr('name').to_s.gsub('_', '-') + "'] = ").ljust(32) + value
        steps = value.split('.')
        conditions = []
        conditions << item.attr("if") if item.has_attribute?('if')
        (steps.size - 1).times do |i|
          conditions << steps[0..i].join(".")
        end if steps.size > 1
        code << " if " + conditions.join(" and ") unless conditions.empty?
        code << "\n"
      end
      return code
    end


  end

end
