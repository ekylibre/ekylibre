module Aggeratio
  class DocumentFragment < Base

    def build
      # Build code
      document_variable = "__doc__"
      code  = parameter_initialization
      code << "#{document_variable} = Nokogiri::HTML::DocumentFragment.parse('')\n"
      code << "builder = Nokogiri::HTML::Builder.with(#{document_variable}) do |xml|\n"
      code << build_element(@root).gsub(/^/, '  ')
      code << "end\n"
      code << "puts #{document_variable}.to_html\n"
      code << "return #{document_variable}.to_html.html_safe\n"
      return code
    end

    def build_element(element)
      method_name = "build_#{element.name}".to_sym
      code = "# "
      if respond_to?(method_name)
        code << "#{element.name}\n"
        code << send(method_name, element)
      else
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
      code  = "xml.ul(:class => '#{items}') do\n"
      code << "  for #{item} in #{element.attr("with") || items}\n"
      code << build_elements(element.xpath('xmlns:variable')).gsub(/^/, '    ')
      # code << build_element(element.xpath("xmlns:title")).gsub(/^/, '    ')
      code << build_attributes_hash(element.xpath("*[self::xmlns:attribute or self::xmlns:title]"), item, :var => "attrs").gsub(/^/, '    ')
      code << "    attrs[:class] = '#{item}'\n"
      code << "    xml.li(attrs) do\n"
      if title = element.xpath('xmlns:title').first
        code << "      xml.h2(" + 
          (title.attr("value") || ("#{item}." + title.attr('name').to_s.gsub('-', '_'))) + 
          ")\n"        
      end
      code << build_elements(element).gsub(/^/, '      ')
      code << "    end\n"
      code << "  end\n"
      code << "end\n"
      return code
    end

    def build_section(element)
      name = element.attr("name").to_s
      code = ""
      code << "xml.section(:id => '#{name}') do\n"
      if title = element.xpath('xmlns:title').first
        code << "  xml.h1(" + 
          (title.attr("value") || ("#{name}." + title.attr('name').to_s.gsub('-', '_'))) + 
          ")\n"        
      end
      code << build_elements(element).gsub(/^/, '  ')
      code << "end\n"
      return code
    end

    def build_variable(element)
      "#{element.attr('name')} = #{element.attr('value')} rescue nil\n"
    end

    def build_title(element)
      "xml.h2(#{element.attr('value')}, :class => '#{element.attr('name')}')\n"
    end

    def build_table(element)
      items = element.attr("name").to_s
      item  = element.attr("for") || items.singularize
      code  = "xml.table(:class => '#{items}') do\n"
      code << "  xml.thead do\n"
      code << "    xml.tr do\n"
      columns = element.xpath("xmlns:column[not(@level) or @level != 'api']")
      for col in columns
        code << "      xml.th(:#{col.attr('name').to_s.split('-').last}.tl)\n"
      end
      code << "    end\n"
      code << "  end\n"
      code << "  xml.tbody do\n"
      code << "    for #{item} in #{element.attr("with") || items}\n"
      code << build_elements(element.xpath('xmlns:variable')).gsub(/^/, '      ')
      code << "      xml.tr(:class => '#{item}') do\n"
      for col in columns
        value = col.attr("value") || ("#{item}." + col.attr('name').to_s.gsub('-', '_'))
        code << "        v = " + value + "\n"
        code << "        xml.td(v, :class => '#{col.attr('name')}')\n"
      end
      # code << build_attributes_hash(element.xpath("xmlns:column"), item, :var => "attrs").gsub(/^/, '    ')
      # code << "    xml.#{item}(attrs)\n"
      # # code << build_elements(element).gsub(/^/, '      ')
      code << "      end\n"
      code << "    end\n"
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
