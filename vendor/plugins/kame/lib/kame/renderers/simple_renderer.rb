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
      code  = "if params[:column] and params[:visibility]\n"
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

      colgroup = columns_definition_code(table)
      header = "'<thead><tr>'+"+columns_to_cells(table, :header, :id=>table.name)+"+'</tr></thead>'"
      footer = footer_code(table)
      body = columns_to_cells(table, :body, :record=>record)

      code  = table.finder.select_data_code(table)
      code += "body = ''\n"
      code += "if #{table.records_variable_name}.size>0\n"
      code += "  reset_cycle('kame')\n"
      code += "  for #{record} in #{table.records_variable_name}\n"
      line_class = "#{'+\' \'+('+table.options[:line_class].to_s.gsub(/RECORD/, record)+').to_s' unless table.options[:line_class].nil?}+cycle(' odd', ' even', :name=>'kame')"
      code += "    body += content_tag(:tr, (#{body}).html_safe, :class=>'data'#{line_class})\n"
      if table.options[:children].is_a? Symbol
        children = table.options[:children].to_s
        child_body = columns_to_cells(table, :children, :record=>child, :order=>table.options[:order])
        code += "    for #{child} in #{record}.#{children}\n"
        code += "      body += content_tag(:tr, (#{child_body}).html_safe, :class=>'data child '#{line_class})\n"
        code += "    end\n"
      end
      code += "  end\n"
      code += "else\n"
      code += "  body = ('<tr class=\"empty\"><td colspan=\"#{table.columns.size}\">'+::I18n.translate('kame.no_records')+'</td></tr>')\n"
      code += "end\n"
      # code += "text = #{colgroup}+#{header}+#{footer}+content_tag(:tbody, body.html_safe)\n"
      code += "text = #{header}+#{footer}+content_tag(:tbody, body.html_safe)\n"
      # code += "text = content_tag(:table, text.html_safe, :class=>:kame, :id=>'#{table.name}') unless request.xhr?\n"
      code += "text = content_tag(:table, text.html_safe, :class=>:kame)\n"
      code += "text = content_tag(:div, text.html_safe, :class=>:kame, :id=>'#{table.name}') unless request.xhr?\n"
      code += "return text\n"
      return code
    end


    def columns_to_cells(table, nature, options={})
      columns = table.columns
      code = ''
      record = options[:record]||'RECORD'
      for column in columns
        if nature==:header
          code += "+\n      " unless code.blank?
          classes = 'hdr '+column_classes(column, true)
          classes = (column.sortable? ? "\"#{classes} sortable \"+(kame_params[:sort]!='#{column.id}' ? 'nsr' : kame_params[:dir])" : "\"#{classes}\"")
          header = "link_to(#{column.header_code}, url_for(params.merge(:action=>:#{table.controller_method_name}, :sort=>#{column.id.to_s.inspect}, :dir=>(kame_params[:sort]!='#{column.id}' ? 'asc' : kame_params[:dir]=='asc' ? 'desc' : 'asc'))), :id=>'#{column.unique_id}', 'data-cells-class'=>'#{column.simple_id}', :class=>#{classes}, 'data-remote-update'=>'#{table.name}')"
          code += "content_tag(:th, #{header}, :class=>\"#{column_classes(column)}\")"
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
                style += "background: #'+"+column.datum_code(record)+"+';"
              elsif column.name==:language and  column.datatype == :string and column.limit <= 8
                datum = "(#{datum}.blank? ? '' : ::I18n.translate('languages.'+#{datum}))"
              elsif column.name==:country and  column.datatype == :string and column.limit <= 8
                datum = "(#{datum}.blank? ? '' : (image_tag('countries/'+#{datum}.to_s+'.png')+' '+::I18n.translate('countries.'+#{datum})).html_safe)"
              elsif column.datatype == :string
                datum = "h("+datum+")"
              end
            else
              datum = 'nil'
            end
            code += "content_tag(:td, #{datum}, :class=>\"#{column_classes(column)}\""
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
            code += ", :class=>\"#{column_classes(column)}\")"
          when TextFieldColumn.name
            code += "content_tag(:td,"
            if nature==:body 
              code += "text_field_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{table.name}_'+#{record}.id.to_s+'_#{column.name}'#{column.options[:size] ? ', :size=>'+column.options[:size].to_s : ''})"
            else
              code += "''"
            end
            code += ", :class=>\"#{column_classes(column)}\")"
          when ActionColumn.name
            code += "content_tag(:td, "+(nature==:body ? column.operation(record) : "''")+", :class=>\"#{column_classes(column)}\")"
          else 
            code += "content_tag(:td, '&#160;&#8709;&#160;'.html_safe)"
          end
        end
      end
      return code
    end


    # Produce the code to create bottom menu and pagination
    def footer_code(table)
      menu = "<div class=\"widget menu\">"
      menu += "<a class=\"start icon im-action\">'+::I18n.translate('kame.menu').gsub(/\'/,'&#39;')+'</a>"
      menu += "<ul>"
      # Column selector
      menu += "<li class=\"columns\">"
      menu += "<a class=\"icon im-table \">'+::I18n.translate('kame.columns').gsub(/\'/,'&#39;')+'</a><ul>"
      for column in table.data_columns
        menu += "<li>'+link_to(#{column.header_code}, url_for(:action=>:#{table.controller_method_name}, :column=>'#{column.id}'), 'data-toggle-column'=>'#{column.unique_id}', :class=>'icon '+(kame_params[:hidden_columns].include?('#{column.id}') ? 'im-unchecked' : 'im-checked'))+'</li>"
      end
      menu += "</ul></li>"
      # Separator
      menu += "<li class=\"separator\"></li>"      
      # Exports
      for format, exporter in Kame.exporters
        menu += "<li class=\"export #{exporter.name}\">'+link_to(::I18n.translate('kame.export_as', :format=>::I18n.translate('kame.export.#{format}')).gsub(/\'/,'&#39;'), {:action=>:#{table.controller_method_name}, :sort=>kame_params[:sort], :dir=>kame_params[:dir], :format=>'#{format}'}, :class=>\"icon im-export\")+'</li>"
      end
      menu += "</ul></div>"
      
      pagination = ''
      if table.finder.paginate?
        # Per page
        list = [5, 10, 25, 50, 100]
        list << table.options[:per_page].to_i if table.options[:per_page].to_i > 0
        list = list.uniq.sort
        pagination += "<div class=\"widget\"><select data-update=\"#{table.name}\" data-per-page=\"'+url_for(params.merge(:action=>:#{table.controller_method_name}, :sort=>kame_params[:sort], :dir=>kame_params[:dir]))+'\">"+list.collect{|n| "<option value=\"#{n}\"'+(kame_params[:per_page] == #{n} ? ' selected=\"selected\"' : '')+'>'+h(::I18n.translate('kame.x_per_page', :count=>#{n}))+'</option>"}.join+"</select></div>"
        # Pages link
        pagination += "'+will_paginate(#{table.records_variable_name}, :class=>'widget pagination', :previous_label=>::I18n.translate('kame.previous'), :next_label=>::I18n.translate('kame.next'), :renderer=>ActionView::RemoteLinkRenderer, :remote=>{'data-remote-update'=>'#{table.name}'}, :params=>{:action=>:#{table.controller_method_name}"+table.parameters.collect{|k,c| ", :#{k}=>kame_params[:#{k}]"}.join+"}).to_s+'"
      end

      code = "('<tfoot><tr><th colspan=\"#{table.columns.size}\">#{menu}#{pagination}</th></tr></tfoot>').html_safe"
      return code
    end

    def columns_definition_code(table)
      code = table.columns.collect do |column|
        "<col id=\\\"#{column.unique_id}\\\" class=\\\"#{column_classes(column, true)}\\\" data-cells-class=\\\"#{column.simple_id}\\\" href=\\\"\#\{url_for(:action=>:#{table.controller_method_name}, :column=>#{column.id.to_s.inspect})\}\\\" />"
      end.join
      return "\"#{code}\"" # "\"<colgroup>#{code}</colgroup>\""
    end

    def column_classes(column, without_id=false)
      column_sort = ''
      column_sort = "\#\{' sor' if kame_params[:sort]=='#{column.id}'\}" if column.sortable?
      column_sort += "\#\{' hidden' if kame_params[:hidden_columns].include?('#{column.id}')\}" if column.is_a? DataColumn
      classes = []
      classes << column.options[:class].to_s.strip unless column.options[:class].blank?
      classes << column.simple_id unless without_id
      if column.is_a? ActionColumn
        classes << :act
      elsif column.is_a? DataColumn
        classes << :col
        classes << DATATYPE_ABBREVIATION[column.datatype]
        classes << :url if column.options[:url].is_a?(Hash)
        classes << column.name if [:code, :color, :country].include? column.name.to_sym
        if column.options[:mode] == :download
          classes << :dld
        elsif column.options[:mode]||column.name == :email
          classes << :eml
        elsif column.options[:mode]||column.name == :website
          classes << :web
        end
      elsif column.is_a? TextFieldColumn
        classes << :tfd
      elsif column.is_a? CheckBoxColumn
        classes << :chk
      end
      return "#{classes.join(" ")}#{column_sort}"
    end


  end
  

end


Kame.register_renderer(:simple_renderer, Kame::SimpleRenderer)
