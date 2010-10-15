module Kame

  class SimpleRenderer < Kame::Renderer

    DATATYPE_ABBREVIATION = {
      :binary => :bin,
      :boolean => :bln,
      :date => :dat,
      :datetime => :dtt,
      :decimal => :dec,
      :float =>:flt,
      :integer =>:int,
      :string =>:str,
      :text => :txt,
      :time => :tim,
      :timestamp => :dtt
    }

    def remote_update_code(table)
      code  = "if params[:column]\n"
      code += "  column = params[:column].to_s\n"
      code += "  kame_params[:hidden_columns].delete(column) if params[:visibility] == 'shown'\n"
      code += "  kame_params[:hidden_columns] << column if params[:visibility] == 'hidden'\n"
      code += "  render(:nothing=>true)\n"
      code += "else\n"
      code += "  render(:inline=>'<%=#{table.view_method_name}-%>')\n" 
      code += "end\n"
      return code
    end

    def build_table_code(table)
      record = "r"
      child  = "c"

      options = table.options
      name = table.name


      colgroup = columns_definition_code(table)
      header = "'<thead><tr>'+"+columns_to_td(table, :header, :id=>table.name)+"+'</tr></thead>'"
      footer = footer_code(table)
      body = columns_to_td(table, :body, :record=>record)

      code  = table.finder.select_data_code(table)
      code += "body = ''\n"
      code += "if #{table.records_variable_name}.size>0\n"
      code += "  sort, dir = options['#{table.name}_sort'], options['#{table.name}_dir']\n"
      code += "  reset_cycle('kame')\n"
      code += "  for #{record} in #{table.records_variable_name}\n"
      line_class = "#{'+\' \'+('+options[:line_class].to_s.gsub(/RECORD/, record)+').to_s' unless options[:line_class].nil?}+cycle(' odd', ' even', :name=>'kame')"
      code += "    body += content_tag(:tr, (#{body}).html_safe, :class=>'data'#{line_class})\n"
      if options[:children].is_a? Symbol
        children = options[:children].to_s
        child_body = columns_to_td(table, :children, :record=>child, :order=>options[:order])
        code += "    for #{child} in #{record}.#{children}\n"
        code += "      body += content_tag(:tr, (#{child_body}).html_safe, :class=>'data child '#{line_class})\n"
        code += "    end\n"
      end
      code += "  end\n"
      code += "else\n"
      code += "  body = ('<tr class=\"empty\"><td colspan=\"#{table.columns.size}\">'+::I18n.translate('kame.no_records')+'</td></tr>')\n"
      code += "end\n"
      code += "text = #{colgroup}+#{header}+#{footer}+content_tag(:tbody, body.html_safe)\n"
      code += "text = content_tag(:table, text.html_safe, :class=>:kame)\n"
      code += "text = content_tag(:div, text.html_safe, :class=>:kame, :id=>'"+name.to_s+"') unless request.xhr?\n"
      code += "return text\n"
      return code
    end


    def columns_to_td(table, nature, options={})
      columns = table.columns
      code = ''
      record = options[:record]||'RECORD'
      for column in columns
        column_sort = ''
        if column.sortable?
          column_sort = "\#\{' sorted' if sort=='#{column.name}'\}"
        end
        if nature==:header
          code += "+\n      " unless code.blank?
          header_title = column.header_code
          if column.sortable?
            url = ":action=>:#{table.controller_method_name}, '#{table.name}_sort'=>'#{column.name}', '#{table.name}_dir'=>(sort=='#{column.name}' and dir=='asc' ? 'desc' : 'asc'), :page=>page"
            header_title = "link_to_remote("+header_title+", {:update=>'#{table.name}', :loading=>'onLoading();', :loaded=>'onLoaded();', :url=>{#{url}}}, {:class=>'sor '+(sort=='#{column.name}' ? dir : 'nsr'), :href=>url_for(#{url})})"
          end
          code += "content_tag(:th, "+header_title+", :class=>\"#{column_classes(column, true)}\")"
        else
          code   += "+\n        " unless code.blank?
          case column.class.name
          when DataColumn.name
            style = column.options[:style]||''
            style = style.gsub(/RECORD/, record)+"+" if style.match(/RECORD/)
            style += "'"
            if nature!=:children or (not column.options[:children].is_a? FalseClass and nature==:children)
              datum = column.datum_code(record, nature==:children)
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
                datum = "(#{datum}.blank? ? '' : link_to(#{datum}, url_for(#{url})))"
              elsif column.options[:mode] == :download# and !datum.nil?
                datum = "(#{datum}.blank? ? '' : link_to(tg('download'), url_for_file_column("+record+",'#{column.name}')))"
              elsif column.options[:mode]||column.name == :email
                # datum = 'link_to('+datum+', "mailto:#{'+datum+'}")'
                datum = "(#{datum}.blank? ? '' : mail_to(#{datum}))"
              elsif column.options[:mode]||column.name == :website
                datum = "(#{datum}.blank? ? '' : link_to("+datum+", "+datum+"))"
              elsif column.name==:color
                style += "background: #'+"+column.data(record)+"+';"
              elsif column.name==:language and  column.datatype == :string and column.limit <= 8
                datum = "(#{datum}.blank? ? '' : ::I18n.translate('languages.'+#{datum}))"
              elsif column.name==:country and  column.datatype == :string and column.limit <= 8
                datum = "(#{datum}.blank? ? '' : (image_tag('countries/'+#{datum}.to_s+'.png')+'&#160;'+::I18n.translate('countries.'+#{datum})).html_safe)"
              elsif column.datatype == :string
                datum = "h("+datum+")"
              end
            else
              datum = 'nil'
            end
            code += "content_tag(:td, #{datum}, :class=>\"#{column_classes(column, true)}\""
            code += ", :style=>"+style+"'" unless style[1..-1].blank?
            code += ")"
          when CheckBoxColumn.name
            code += "content_tag(:td,"
            if nature==:body 
              code += "hidden_field_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', 0, :id=>nil)+"
              code += "check_box_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', 1, #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{table.name}_'+#{record}.id.to_s+'_#{column.name}')"
            else
              code += "''"
            end
            code += ", :class=>'chk')"
          when TextFieldColumn.name
            code += "content_tag(:td,"
            if nature==:body 
              code += "text_field_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{table.name}_'+#{record}.id.to_s+'_#{column.name}'#{column.options[:size] ? ', :size=>'+column.options[:size].to_s : ''})"
            else
              code += "''"
            end
            code += ", :class=>'txt')"
          when ActionColumn.name
            code += "content_tag(:td, "+(nature==:body ? column.operation(record) : "''")+", :class=>\"#{column_classes(column, true)}\")"
          else 
            code += "content_tag(:td, '&#160;&#8709;&#160;'.html_safe)"
          end
        end
      end
      return code
    end


    # Produce the code to create bottom menu and pagination
    def footer_code(table)
      menu = "<div class=\"menu\">"
      menu += "<a class=\"icon im-action\">'+::I18n.translate('kame.menu').gsub(/\'/,'&#39;')+'</a>"
      menu += "<ul>"
      # Column selector
      menu += "<li class=\"columns\">"
      menu += "<a class=\"icon im-table \">'+::I18n.translate('kame.columns').gsub(/\'/,'&#39;')+'</a><ul>"
      for column in table.data_columns
        menu += "<li>'+link_to(#{column.header_code}, '#', 'toggle-column'=>'#{column.unique_id}', :class=>'icon '+(kame_params[:hidden_columns].include?('#{column.id}') ? 'im-unchecked' : 'im-checked'))+'</li>"
      end
      menu += "</a>"
      menu += "</ul></li>"
      # Separator
      menu += "<li class=\"separator\"></li>"      
      # Exports
      for format, exporter in Kame.exporters
        menu += "<li class=\"export #{exporter.name}\">'+link_to(::I18n.translate('kame.export_as', :format=>::I18n.translate('kame.export.#{format}')).gsub(/\'/,'&#39;'), {:action=>:#{table.controller_method_name}, '#{table.name}_sort'=>params['#{table.name}_sort'], '#{table.name}_dir'=>params['#{table.name}_dir'], :format=>'#{format}'}, :class=>\"icon im-export\")+'</li>"
      end
      menu += "</div>"

      # Pages link
      pagination = ''
      pagination = "'+will_paginate(#{table.records_variable_name}, :previous_label => ::I18n.translate('kame.previous'), :next_label => ::I18n.translate('kame.next'), :renderer=>ActionView::RemoteLinkRenderer, :remote=>{:update=>'#{table.name}', :loading=>'onLoading();', :loaded=>'onLoaded();'}, :params=>{'#{table.name}_sort'=>params['#{table.name}_sort'], '#{table.name}_dir'=>params['#{table.name}_dir'], '#{table.name}_per_page'=>params['#{table.name}_per_page'], :action=>:#{table.controller_method_name}}).to_s+'" if table.finder.paginate?
      
      code = "('<tfoot><tr class=\"footer\"><th colspan=\"#{table.columns.size}\">#{menu}#{pagination}</th></tr></tfoot>').html_safe"
      return code
    end

    def columns_definition_code(table)
      code = table.columns.collect do |column|
        "<col id=\\\"#{column.unique_id}\\\" class=\\\"#{column_classes(column)}\\\" cells-class=\\\"#{column.simple_id}\\\" href=\\\"\#\{url_for(:action=>:#{table.controller_method_name}, :column=>#{column.id.to_s.inspect})\}\\\"></col>"
      end.join
      return "\"#{code}\"" # "\"<colgroup>#{code}</colgroup>\""
    end

    def column_classes(column, with_id=false)
      column_sort = ''
      column_sort = "\#\{' sor' if sort=='#{column.name}'\}" if column.sortable?
      column_sort += "\#\{' hidden' if kame_params[:hidden_columns].include?('#{column.id}')\}" if column.is_a? DataColumn
      classes = []
      classes << column.options[:class].to_s.strip unless column.options[:class].blank?
      classes <<  column.simple_id if with_id
      if column.is_a? ActionColumn
        classes << :act
      elsif column.is_a? DataColumn
        classes << :col
        classes << DATATYPE_ABBREVIATION[column.datatype]
        classes << :url if column.options[:url].is_a?(Hash)
        classes << column.name if [:code, :color].include? column.name.to_sym
        if column.options[:mode] == :download
          classes << :dld
        elsif column.options[:mode]||column.name == :email
          classes << :eml
        elsif column.options[:mode]||column.name == :website
          classes << :web
        end
      end
      return "#{classes.join(" ")}#{column_sort}"
    end


  end
  

end


Kame.register_renderer(:simple_renderer, Kame::SimpleRenderer)
