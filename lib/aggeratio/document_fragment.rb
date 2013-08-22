# -*- coding: utf-8 -*-
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
      code = ""
      if respond_to?(method_name)
        # code << "#{element.name}\n"
        code << send(method_name, element)
      else
        code << "# #{element.name}: not implemented\n"
      end
      return code
    end

    def build_elements(elements)
      code = ""
      for element in elements
        next if ["title"].include?(element.name.to_s)
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
      code  = "for #{item} in #{element.attr("in")}\n"
      code << build_section(element).gsub(/^/, '  ')
      code << "end\n"
      if element.has_attribute?("name")
        code = "xml.section(:class => 'sections') do\n" + code.strip.gsub(/^/, '  ') + "\nend\n"
      end
      return code
    end

    def build_section(element)
      name = element.attr("name").to_s
      code = ""
      code << "xml.section do\n"
      if title = element.xpath('xmlns:title').first
        type = (element.has_attribute?("name") ? element.attr('name') : element.has_attribute?("for") ? element.attr('for') : nil)
        if type.blank?
          code << "  xml.h1(#{value_of(title)}) rescue nil\n"
        else
          code << "  xml.h1(:section_x.tl(:section => :#{type}.tl(:default => [:'activerecord.models.#{type}', '#{type.humanize}']), :x => #{value_of(title)})) rescue nil\n"
        end
      end
      code << "  xml.div(:class => 'section-content') do\n"
      code << build_children_of(element).gsub(/^/, '    ')
      code << "  end\n"
      code << "end\n"
      return code
    end

    def build_variable(element)
      "#{element.attr('name')} = #{value_of(element)} rescue nil\n"
    end

    def build_title(element)
      "xml.h2(#{value_of(element)}, :class => '#{element.attr('name')}') rescue nil\n"
    end

    def build_property(element)
      return "" if element.attr("level") == "api"
      code  = "xml.dl do\n"
      code << "  xml.dd(#{human_name_of(element)})\n"
      code << "  xml.dt(#{value_of(element)}) rescue nil\n"
      code << "end\n"
      return code
    end

    def build_matrix(element, mode = :table, vertical = false)
      item  = element.attr("for")
      columns = element.xpath("*[(self::xmlns:cell or self::xmlns:matrix) and (not(@level) or @level != 'api')]")
      code = ""
      code  = "xml.table(:class => 'matrix') do\n"

      if mode == :table or mode == :head
        code << "  xml.thead do\n"
        code << build_table_serie(columns, vertical) do |col, ccode|
          if col.name == "cell"
            ccode << "xml.th(#{human_name_of(col)}, :class => '#{normalize_name(col)}')\n"
          elsif col.name == "matrix"
            ccode << "xml.th(:class => 'matrix #{normalize_name(col)}') do\n"
            # ccode << "  xml.em(#{human_name_of(col)})\n"
            ccode << build_matrix(col, :head, !vertical).strip.gsub(/^/, '  ') + "\n"
            ccode << "end\n"
          end
        end.strip.gsub(/^/, '    ') + "\n"
        code << "  end\n"
      end

      if mode == :table or mode == :body
        code << "  xml.tbody do\n"

        body_code  = build_elements(element.xpath('xmlns:variable'))
        body_code << build_table_serie(columns, vertical) do |col, ccode|
          if col.name == "cell"
            ccode << "xml.td(#{value_of(col)}, :class => '#{normalize_name(col)}')\n"
          elsif col.name == "matrix"
            ccode << "xml.td(:class => 'matrix #{normalize_name(col)}') do\n"
            ccode << build_matrix(col, :body, !vertical).gsub(/^/, '  ')
            ccode << "end\n"
          end
        end

        if element.has_attribute?("in")
          code << "    for #{item} in #{element.attr("in")}\n"
          code << body_code.strip.gsub(/^/, '      ') + "\n"
          code << "    end\n"
        else
          code << body_code.strip.gsub(/^/, '    ') + "\n"
        end
        code << "  end\n"
      end

      code << "end\n"
      return code
    end

    def build_properties_hash(items, object, options = {})
      var = options[:var] || "properties"
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

    def build_table_serie(elements, vertical = false, &block)
      code = ""
      if vertical
        for element in elements
          code << "xml.tr do\n"
          element_code = ""
          yield(element, element_code)
          code << element_code.strip.gsub(/^/, '  ') + "\n"
          code << "end\n"
        end
      else
        code << "xml.tr do\n"
        for element in elements
          element_code = ""
          yield(element, element_code)
          code << element_code.strip.gsub(/^/, '  ') + "\n"
        end
        code << "end\n"
      end
      return code
    end

  end

end
