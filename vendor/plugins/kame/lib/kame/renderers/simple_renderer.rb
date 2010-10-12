module Kame

  class SimpleRenderer < Kame::Renderer

    def build_table_code(table)
      record = "r"
      child  = "c"

      header = columns_to_td(table, :header, :id=>table.name)
      body = columns_to_td(table, :body, :record=>record)
      if table.options[:children].is_a? Symbol
      end          

      code += "if #{table.records_variable_name}.size>0\n"
      code += "  reset_cycle('kame')\n"
      code += "  body = ''\n"
      code += "  for #{record} in #{table.records_variable_name}\n"
      line_class = "#{'+\' \'+('+table.options[:line_class].to_s.gsub(/RECORD/, record)+').to_s' unless table.options[:line_class].nil?}+cycle(' odd', ' even', :name=>'kame')"
      code += "    body += content_tag(:tr, (#{body}).html_safe, :class=>'data'#{line_class})\n"
      if table.options[:children].is_a? Symbol
        children = options[:children].to_s
        child_body = columns_to_td(table, :children, :record=>child, :order=>options[:order])
        code += "      for #{child} in #{record}.#{children}\n"
        code += "        body += content_tag(:tr, (#{child_body}).html_safe, :class=>'data child '#{line_class})\n"
        code += "      end\n"
      end
      code += "    end\n"
      code += footer.gsub(/^/, '    ')
      code += "    text = content_tag(:thead, #{header})+content_tag(:tfoot, #{footer_var}.html_safe)+content_tag(:tbody, body.html_safe)\n"
      code += "  else\n"
      if options[:empty]
        code += "    text = ''\n"
      else
        code += "    text = content_tag(:thead, #{header})+('<tr class=\"empty\"><td colspan=\"#{table.columns.size}\">'+::I18n.translate('kame.no_records')+'</td></tr>').html_safe\n"
      end
      code += "  end\n"
      code += footer;
      # code += "  text = content_tag(:table, text, :class=>:kame, :id=>'"+name.to_s+"') unless request.xhr?\n"
      code += "  text = content_tag(:table, text.html_safe, :class=>:kame)\n"
      code += "  text = content_tag(:div, text.html_safe, :class=>:kame, :id=>'"+name.to_s+"') unless request.xhr?\n"
      code += "  return text\n"
      return code
    end


    def columns_to_td(table, nature, options={})
      columns = table.columns
      code = ''
      record = options[:record]||'RECORD'
      list_method_name = table.controller_method_name
      for column in columns
        column_sort = ''
        if column.sortable?
          column_sort = "\#\{' sorted' if sort=='#{column.name}'\}"
        end
        if nature==:header
          code += "+\n      " unless code.blank?
          header_title = column.header_code
          if column.sortable?
            url = ":action=>:#{list_method_name}, '#{options[:id]}_sort'=>'"+column.name.to_s+"', '#{options[:id]}_dir'=>(sort=='"+column.name.to_s+"' and dir=='asc' ? 'desc' : 'asc'), :page=>page"
            header_title = "link_to_remote("+header_title+", {:update=>'"+options[:id].to_s+"', :loading=>'onLoading();', :loaded=>'onLoaded();', :url=>url_for(#{url})}, {:class=>'sort '+(sort=='"+column.name.to_s+"' ? dir : 'unsorted'), :href=>url_for(#{url})})"
          end
          code += "content_tag(:th, "+header_title+", :class=>\""+(column.action? ? 'act' : 'col')+column_sort+"\")"
        else
          code   += "+\n        " unless code.blank?
          case column.nature
          when :column
            style = column.options[:style]||''
            style = style.gsub(/RECORD/, record)+"+" if style.match(/RECORD/)
            style += "'"
            css_class = column.options[:class] ? ' '+column.options[:class].to_s : ''
            if nature!=:children or (not column.options[:children].is_a? FalseClass and nature==:children)
              datum = column.data(record, nature==:children)
              if column.datatype == :boolean
                datum = "content_tag(:div, '', :class=>'checkbox-'+("+datum.to_s+" ? 'true' : 'false'))"
              end
              if [:date, :datetime, :timestamp].include? column.datatype
                datum = "(#{datum}.nil? ? '' : ::I18n.localize(#{datum}))"
              end
              if column.datatype == :decimal
                datum = "(#{datum}.nil? ? '' : number_to_currency(#{datum}, :separator=>',', :delimiter=>'&#160;', :unit=>'', :precision=>#{column.options[:precision]||2}))"
              end
              if column.options[:url].is_a?(Hash) and nature==:body
                column.options[:url][:id] ||= column.record(record)+'.id'
                url = column.options[:url].collect{|k, v| ":#{k}=>"+(v.is_a?(String) ? v.gsub(/RECORD/, record) : v.inspect)}.join(", ")
                datum = "("+datum+".blank? ? '' : link_to("+datum+', url_for('+url+')))'
                css_class += ' url'
              elsif column.options[:mode] == :download# and !datum.nil?
                datum = "("+datum+".blank? ? '' : link_to(tg('download'), url_for_file_column("+record+",'#{column.name}')))"
                css_class += ' download'
              elsif column.options[:mode]||column.name == :email
                # datum = 'link_to('+datum+', "mailto:#{'+datum+'}")'
                datum = "("+datum+".blank? ? '' : link_to("+datum+", \"mailto:\#\{"+datum+"\}\"))"
                css_class += ' web'
              elsif column.options[:mode]||column.name == :website
                datum = "("+datum+".blank? ? '' : link_to("+datum+", "+datum+"))"
                css_class += ' web'
              elsif column.name==:color
                css_class += ' color'
                style += "background: #'+"+column.data(record)+"+';" # +"+'; color:#'+viewable("+column.data(record)+")+';"
              elsif column.name==:language and  column.datatype == :string and column.limit <= 8
                datum = "(#{datum}.blank? ? '' : ::I18n.translate('languages.'+#{datum}))"
              elsif column.name==:country and  column.datatype == :string and column.limit <= 8
                datum = "(#{datum}.blank? ? '' : ('<nobr>'+image_tag('countries/'+#{datum}.to_s+'.png')+'&#160;'+::I18n.translate('countries.'+#{datum})+'</nobr>').html_safe)"
              elsif column.datatype == :string
                datum = "h("+datum+")"
              end
              if column.name==:code
                css_class += ' code'
              end
            else
              datum = 'nil'
            end
            css_class = column.datatype.to_s+css_class
            css_class = ", :class=>\""+css_class+column_sort+"\"" if css_class.strip.size > 0 or column_sort.strip.size > 0
            code += "content_tag(:td, "+datum+css_class
            code += ", :style=>"+style+"'" unless style[1..-1].blank?
            code += ")"
          when :check
            code += "content_tag(:td,"
            if nature==:body 
              code += "hidden_field_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', 0, :id=>nil)+"
              code += "check_box_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', 1, #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{table.name}_'+#{record}.id.to_s+'_#{column.name}')"
            else
              code += "''"
            end
            code += ", :class=>'chk')"
          when :textbox
            code += "content_tag(:td,"
            if nature==:body 
              code += "text_field_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{table.name}_'+#{record}.id.to_s+'_#{column.name}'#{column.options[:size] ? ', :size=>'+column.options[:size].to_s : ''})"
            else
              code += "''"
            end
            code += ", :class=>'txt')"
          when :action
            code += "content_tag(:td, "+(nature==:body ? column.operation(record) : "''")+", :class=>'act')"
          else 
            code += "content_tag(:td, '&#160;&#8709;&#160;')"
          end
        end
      end
      

    end


  end
