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
      code = ""
      if respond_to?(method_name)
        # code << "#{element.name}\n"
        code << send(method_name, element)
      else
        Rails.logger.warn("Markup <#{element.name}> is unknown or not implemented")
        code << "# #{element.name}: not implemented\n"
      end
      return code
    end

    def build_elements(elements)
      code = ""
      for element in elements
        next if ["property", "title"].include?(element.name.to_s)
        code << build_element(element)
      end
      code << "# No elements\n" if code.blank?
      return code
    end

    def build_children_of(element)
      return build_elements(element.children)
    end

    def build_sections(element)
      item  = element.attr("for")
      code  =  "for #{item} in #{element.attr("in")}\n"
      code << build_elements(element.xpath('xmlns:variable')).gsub(/^/, '  ')
      code << build_properties_hash(element.xpath("*[self::xmlns:property or self::xmlns:title]"), :var => "attrs").gsub(/^/, '  ')
      code << "  xml.#{item}(attrs) do\n"
      code << build_children_of(element).gsub(/^/, '    ')
      code << "  end\n"
      code << "end\n"
      if element.has_attribute?("name")
        code = "xml.send('#{normalize_name(element)}') do\n" + code.strip.gsub(/^/, '  ') + "\nend\n"
      end
      return code
    end

    def build_section(element)
      name = element.attr("name").to_s
      code = ""
      code << build_elements(element.xpath("xmlns:variable"))
      code << build_properties_hash(element.xpath("*[self::xmlns:property or self::xmlns:title]"), :var => "attrs")
      code << "xml.send('#{normalize_name(name)}', attrs) do\n"
      code << build_elements(element.xpath("*[not(self::xmlns:variable)]")).gsub(/^/, '  ')
      code << "end\n"
      return code
    end

    def build_variable(element)
      return "#{element.attr('name')} = #{value_of(element)}\n"
    end

    def build_matrix(element)
      item  = element.attr("for")
      code = build_children_of(element) # .gsub(/^/, '    ')
      if element.has_attribute?("in")
        code  = "for #{item} in #{element.attr("in")}\n" +
          build_elements(element.xpath('xmlns:variable')).gsub(/^/, '  ') +
          "  xml.#{item} do\n" +
          code.gsub(/^/, '    ') +
          "  end\n" +
          "end\n"
      end
      if element.has_attribute?("name")
        code = "xml.send('#{normalize_name(element)}') do\n" + code.strip.gsub(/^/, '  ') + "\nend\n"
      end
      return code
    end

    def build_cell(element)
      code = "xml.send('#{normalize_name(element)}', #{value_of(element)})"
      if element.has_attribute?('if')
        code = "if #{element.attr('if')}\n" + code.gsub(/^/, '  ') + "\nend"
      end
      code << "\n"
      return code
    end

    def build_properties_hash(items, options = {})
      var = options[:var] || "properties"
      code = "#{var} = {}\n"
      max = items.collect{|i| i.attr("name").size}.max
      items.collect do |item|
        code << ("#{var}['" + normalize_name(item) + "'] = ").ljust(max + 7 + var.size) + value_of(item)
        # code << " rescue nil"
        if item.has_attribute?('if')
          code = "if #{item.attr('if')}\n" + code.gsub(/^/, '  ') + "\nend"
        end
        code << "\n"
      end
      return code
    end


  end

end
