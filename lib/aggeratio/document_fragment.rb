# -*- coding: utf-8 -*-
module Aggeratio
  class DocumentFragment < Base
    def initialize(aggregator)
      super(aggregator)
      @minimum_level = :human
    end

    def build
      # Build code
      document_variable = '__doc__'
      code  = parameter_initialization
      code << "#{document_variable} = Nokogiri::HTML::DocumentFragment.parse('')\n"
      code << "builder = Nokogiri::HTML::Builder.with(#{document_variable}) do |xml|\n"
      code << build_element(@root).dig
      code << "end\n"
      code << "return #{document_variable}.to_html.html_safe\n"
      code
    end

    def build_element(element)
      method_name = "build_#{element.name}".to_sym
      code = ''
      if respond_to?(method_name)
        code << conditionate(send(method_name, element), element)
      else
        Rails.logger.warn("Markup <#{element.name}> is unknown or not implemented")
        code << "# #{element.name}: not implemented\n"
      end
      code
    end

    def build_elements(elements)
      code = ''
      for element in elements
        next if ['title'].include?(element.name.to_s)
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
      code << conditionate(build_section(element), element).dig
      code << "end\n"
      if element.has_attribute?('name')
        code = "xml.section(:class => 'sections') do\n" + code.dig + "end\n"
      end
      code
    end

    def build_section(element)
      name = element.attr('name').to_s
      code = ''
      code << "xml.section do\n"
      if title = element.xpath('xmlns:title').first
        type = (element.has_attribute?('name') ? element.attr('name') : element.has_attribute?('for') ? element.attr('for') : nil)
        if type.blank?
          # code << "  xml.h1(#{human_value_of(title)})\n"
          code << human_value_of(title, :h1).dig
        else
          code << "  xml.h1 do\n"
          code << "    xml.span('aggregator_properties.#{type}'.t(default: [:'attributes.#{type}', :'labels.#{type}', :'activerecord.models.#{type}', '#{type.humanize}']))\n"
          code << "    xml.text(' ')\n"
          # code << "    xml.em(#{human_value_of(title)})\n"
          code << human_value_of(title, :em).dig(2)
          code << "  end\n"
          # code << "  xml.h1(:section_x.tl(:section => :#{type}.tl(:default => [:'activerecord.models.#{type}', '#{type.humanize}']), :x => '<em>' + CGI::escapeHTML(#{human_value_of(title)}) + '</em>'))\n" #
        end
      end
      code << "  xml.div(:class => 'section-content') do\n"
      code << build_children_of(element).dig(2)
      code << "  end\n"
      code << "end\n"
      code
    end

    def build_property(element)
      # return "" if element.attr("level") == "api"
      code  = "xml.dl do\n"
      code << "  xml.dd(#{human_name_of(element)})\n"
      # code << "  xml.dt(#{human_value_of(element)})\n"
      code << human_value_of(element, :dt).dig
      code << "end\n"
      code
    end

    def build_matrix(element, mode = :table, vertical = false)
      item  = element.attr('for')
      columns = element.xpath("*[(self::xmlns:cell or self::xmlns:matrix) and (not(@level) or @level != 'api')]")
      code = ''
      code  = "xml.table(:class => 'matrix') do\n"

      if mode == :table || mode == :head
        code << "  xml.thead do\n"
        code << build_table_serie(columns, vertical) do |col, cell_code|
          if col.name == 'cell'
            cell_code << "xml.th(#{human_name_of(col)}, :class => '#{normalize_name(col)}')\n"
          elsif col.name == 'matrix'
            cell_code << "xml.th(:class => 'matrix #{normalize_name(col)}') do\n"
            # cell_code << "  xml.em(#{human_name_of(col)})\n"
            cell_code << build_matrix(col, :head, !vertical).dig
            cell_code << "end\n"
          end
        end.dig(2)
        code << "  end\n"
      end

      if mode == :table || mode == :body
        code << "  xml.tbody do\n"

        body_code  = build_elements(element.xpath('xmlns:variable'))
        body_code << build_table_serie(columns, vertical) do |col, cell_code|
          if col.name == 'cell'
            if col.has_attribute?('if')
              cell_code << "xml.td(:class => '#{normalize_name(col)}') do\n"
              cell_code << conditionate(human_value_of(col), col).dig
              cell_code << "end\n"
            else
              # cell_code << "xml.td(#{human_value_of(col)}, :class => '#{normalize_name(col)}')\n"
              cell_code << human_value_of(col, :td, class: normalize_name(col))
            end
          elsif col.name == 'matrix'
            cell_code << "xml.td(:class => 'matrix #{normalize_name(col)}') do\n"
            cell_code << conditionate(build_matrix(col, :body, !vertical), col).dig
            cell_code << "end\n"
          end
        end

        if element.has_attribute?('in')
          code << "    for #{item} in #{element.attr('in')}\n"
          code << body_code.dig(3)
          code << "    end\n"
        else
          code << body_code.dig(2)
        end
        code << "  end\n"
      end

      code << "end\n"
      code
    end

    def build_table_serie(elements, vertical = false, &_block)
      code = ''
      if vertical
        for element in elements
          code << "xml.tr do\n"
          element_code = ''
          yield(element, element_code)
          code << element_code.dig
          code << "end\n"
        end
      else
        code << "xml.tr do\n"
        for element in elements
          element_code = ''
          yield(element, element_code)
          code << element_code.dig
        end
        code << "end\n"
      end
      code
    end
  end
end
