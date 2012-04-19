module List

  class SimpleRenderer < List::Renderer

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
      code << "  column = params[:column].to_s\n"
      code << "  list_params[:hidden_columns].delete(column) if params[:visibility] == 'shown'\n"
      code << "  list_params[:hidden_columns] << column if params[:visibility] == 'hidden'\n"
      code << "  render(:nothing=>true)\n"
      code << "else\n"
      code << "  render(:inline=>'<%=#{table.view_method_name}-%>')\n" 
      code << "end\n"
      return code
    end

    def build_table_code(table)
      record = "r"
      child  = "c"
      style_class = "list"

      colgroup = columns_definition_code(table)
      header = header_code(table)
      footer = footer_code(table)
      body = columns_to_cells(table, :body, :record=>record)

      code  = table.finder.select_data_code(table)
      code << "body = ''\n"
      code << "if #{table.records_variable_name}.size>0\n"
      code << "  reset_cycle('list')\n"
      code << "  for #{record} in #{table.records_variable_name}\n"
      line_class = "#{'+\' \'+('+table.options[:line_class].to_s.gsub(/RECORD/, record)+').to_s' unless table.options[:line_class].nil?}+cycle(' odd', ' even', :name=>'list')"
      code << "    body << content_tag(:tr, (#{body}).html_safe, :class=>'data'#{line_class})\n"
      if table.options[:children].is_a? Symbol
        children = table.options[:children].to_s
        child_body = columns_to_cells(table, :children, :record=>child, :order=>table.options[:order])
        code << "    for #{child} in #{record}.#{children}\n"
        code << "      body << content_tag(:tr, (#{child_body}).html_safe, :class=>'data child '#{line_class})\n"
        code << "    end\n"
      end
      code << "  end\n"
      code << "else\n"
      code << "  body = ('<tr class=\"empty\"><td colspan=\"#{table.columns.size+1}\">' << ::I18n.translate('list.no_records') << '</td></tr>')\n"
      code << "end\n"
      # code << "text = #{colgroup} << #{header} << #{footer} << content_tag(:tbody, body.html_safe)\n"
      code << "text = #{header} << #{footer} << content_tag(:tbody, body.html_safe)\n"
      code << "if block_given?\n"
      code << "  text << capture("+table.columns.collect{|c| {:name=>c.name, :id=>c.id}}.inspect+", &block).html_safe\n"
      code << "end\n"


      # code << "text = content_tag(:table, text.html_safe, :class=>:#{style_class}, :id=>'#{table.name}') unless request.xhr?\n"
      code << "text = content_tag(:table, text.html_safe, :class=>'#{style_class}')\n"
      # code << "text << '<div class=\"#{style_class}-slider\"><div class=\"#{style_class}-slider-handle\"></div></div>'\n"
      code << "text = content_tag(:div, text.html_safe, :class=>'#{style_class}', :id=>'#{table.name}') unless request.xhr?\n"
      code << "return text\n"
      return code
    end


    def columns_to_cells(table, nature, options={})
      columns = table.columns
      code = ''
      record = options[:record]||'RECORD'
      for column in columns
        if nature==:header
          classes = 'hdr '+column_classes(column, true)
          classes = (column.sortable? ? "\"#{classes} sortable \"+(list_params[:sort]!='#{column.id}' ? 'nsr' : list_params[:dir])" : "\"#{classes}\"")
          header = "link_to("+(column.sortable? ? "content_tag(:span, #{column.header_code}, :class=>'text')+content_tag(:span, '', :class=>'icon')" : "content_tag(:span, #{column.header_code}, :class=>'text')")+", url_for(params.merge(:action=>:#{table.controller_method_name}, :sort=>#{column.id.to_s.inspect}, :dir=>(list_params[:sort]!='#{column.id}' ? 'asc' : list_params[:dir]=='asc' ? 'desc' : 'asc'))), :id=>'#{column.unique_id}', 'data-cells-class'=>'#{column.simple_id}', :class=>#{classes}, :remote=>true, 'data-list-update'=>'##{table.name}', 'data-type'=>'html')"
          code << "content_tag(:th, #{header}, :class=>\"#{column_classes(column)}\")"
          code << "+\n      "#  unless code.blank?
        else
          case column.class.name
          when DataColumn.name
            style = column.options[:style]||''
            style = style.gsub(/RECORD/, record)+"+" if style.match(/RECORD/)
            style << "'"
            if nature!=:children or (not column.options[:children].is_a? FalseClass and nature==:children)
              datum = column.datum_code(record, nature==:children)
              if column.datatype == :boolean
                datum = "content_tag(:div, '', :class=>'checkbox-'+("+datum.to_s+" ? 'true' : 'false'))"
              end
              if [:date, :datetime, :timestamp].include? column.datatype
                datum = "(#{datum}.nil? ? '' : ::I18n.localize(#{datum}))"
              end
              if !column.options[:currency].is_a?(FalseClass) and (currency = column.options[:currency]) # column.datatype == :decimal and 
                currency = currency[nature] if currency.is_a?(Hash)
                currency = :currency if currency.is_a?(TrueClass)
                currency = "RECORD.#{currency}" if currency.is_a?(Symbol)
                raise Exception.new("Option :currency is not valid. Hash, Symbol or true/false") unless currency.is_a?(String)
                currency.gsub!(/RECORD/, record)
                # datum = "(#{datum}.nil? ? '' : number_to_money(#{datum}, #{currency}))"
                datum = "(#{datum}.nil? ? '' : I18n.localize(#{datum}, :currency => #{currency}))"
              elsif column.datatype == :decimal
                # datum = "(#{datum}.nil? ? '' : number_to_currency(#{datum}, :separator=>',', :delimiter=>'&#160;', :unit=>'', :precision=>#{column.options[:precision]||2})).gsub(//)"
                datum = "(#{datum}.nil? ? '' : I18n.localize(#{datum}))"
              end
              if column.options[:url].is_a?(TrueClass) and nature==:body
                datum = "(#{datum}.blank? ? '' : link_to(#{datum}, {:controller=>:#{column.class_name.underscore.pluralize}, :action=>:show, :id=>#{column.record_expr(record)+'.id'}}))"
              elsif column.options[:url].is_a?(Hash) and nature==:body
                column.options[:url][:id] ||= column.record_expr(record)+'.id'
                column.options[:url][:action] ||= :show
                column.options[:url][:controller] ||= column.class_name.underscore.pluralize.to_sym
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
                style << "background: #'+"+column.datum_code(record)+"+';"
              elsif column.name.to_s.match(/(^|\_)currency$/) and column.datatype == :string and column.limit == 3
                datum = "(#{datum}.blank? ? '' : Numisma.currencies[#{datum}].label)"
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
            code << "content_tag(:td, #{datum}, :class=>\"#{column_classes(column)}\""
            code << ", :style=>"+style+"'" unless style[1..-1].blank?
            code << ")"
          when CheckBoxColumn.name
            code << "content_tag(:td,"
            if nature==:body 
              code << "hidden_field_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', 0, :id=>nil)+"
              code << "check_box_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', 1, #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{table.name}_'+#{record}.id.to_s+'_#{column.name}')"
            else
              code << "''"
            end
            code << ", :class=>\"#{column_classes(column)}\")"
          when TextFieldColumn.name
            code << "content_tag(:td,"
            if nature==:body 
              code << "text_field_tag('#{table.name}['+#{record}.id.to_s+'][#{column.name}]', #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{table.name}_'+#{record}.id.to_s+'_#{column.name}'#{column.options[:size] ? ', :size=>'+column.options[:size].to_s : ''})"
            else
              code << "''"
            end
            code << ", :class=>\"#{column_classes(column)}\")"
          when ActionColumn.name
            code << "content_tag(:td, "+(nature==:body ? column.operation(record) : "''")+", :class=>\"#{column_classes(column)}\")"
          else 
            code << "content_tag(:td, '&#160;&#8709;&#160;'.html_safe)"
          end
          code   << "+\n        " #  unless code.blank?
        end
      end
      if nature==:header
        code << "'<th class=\"spe\">#{menu_code(table)}</th>'"
      else
        code << "content_tag(:td)"
      end

      return code
    end


    # Produces main menu code
    def menu_code(table)
      menu = "<div class=\"list-menu\">"
      menu << "<a class=\"list-menu-start\"><span class=\"icon\"></span><span class=\"text\">' + h(::I18n.translate('list.menu').gsub(/\'/,'&#39;')) + '</span></a>"
      menu << "<ul>"
      if table.finder.paginate?
        # Per page
        list = [5, 10, 25, 50, 100]
        list << table.options[:per_page].to_i if table.options[:per_page].to_i > 0
        list = list.uniq.sort
        menu << "<li class=\"per-page parent\">"
        menu << "<a class=\"pages\"><span class=\"icon\"></span><span class=\"text\">' + ::I18n.translate('list.items_per_page').gsub(/\'/,'&#39;') + '</span></a><ul>"
        for n in list
          menu << "<li><a'+(list_params[:per_page] == #{n} ? ' class=\"check\"' : '')+' href=\"'+url_for(params.merge(:action=>:#{table.controller_method_name}, :sort=>list_params[:sort], :dir=>list_params[:dir], :per_page=>#{n}))+'\" data-remote=\"true\" data-list-update=\"##{table.name}\"><span class=\"icon\"></span><span class=\"text\">'+h(::I18n.translate('list.x_per_page', :count=>#{n}))+'</span></a></li>"
        end
        menu << "</ul></li>"
      end

      # Column selector
      menu << "<li class=\"columns parent\">"
      menu << "<a class=\"columns\"><span class=\"icon\"></span><span class=\"text\">' + ::I18n.translate('list.columns').gsub(/\'/,'&#39;') + '</span></a><ul>"
      for column in table.data_columns
        menu << "<li>'+link_to(url_for(:action=>:#{table.controller_method_name}, :column=>'#{column.id}'), 'data-toggle-column'=>'#{column.unique_id}', :class=>'icon '+(list_params[:hidden_columns].include?('#{column.id}') ? 'unchecked' : 'checked')) { '<span class=\"icon\"></span>'.html_safe + content_tag('span', #{column.header_code}, :class=>'text')}+'</li>"
      end
      menu << "</ul></li>"
      # Separator
      menu << "<li class=\"separator\"></li>"      
      # Exports
      for format, exporter in List.exporters
        menu << "<li class=\"export #{exporter.name}\">' + link_to(params.merge(:action=>:#{table.controller_method_name}, :sort=>list_params[:sort], :dir=>list_params[:dir], :format=>'#{format}'), :class=>\"export\") { '<span class=\"icon\"></span>'.html_safe + content_tag('span', ::I18n.translate('list.export_as', :exported=>::I18n.translate('list.export.formats.#{format}')).gsub(/\'/,'&#39;'), :class=>'text')} + '</li>"
      end
      menu << "</ul></div>"
      return menu
    end

    # Produces the code to create the header line using  top-end menu for columns
    # and pagination management
    def header_code(table)
      return "'<thead><tr>' + "+columns_to_cells(table, :header, :id=>table.name)+" + '</tr></thead>'"
    end

    # Produces the code to create bottom menu and pagination
    def footer_code(table)
      code, pagination = '', ''

      if table.finder.paginate?
        # Pages link # , :renderer=>ActionView::RemoteLinkRenderer, :remote=>{'data-remote-update'=>'#{table.name}'}
        pagination << "' << will_paginate(#{table.records_variable_name}, :class=>'widget pagination', :previous_label=>::I18n.translate('list.previous'), :next_label=>::I18n.translate('list.next'), 'data-list'=>'##{table.name}', :params=>{:action=>:#{table.controller_method_name}"+table.parameters.collect{|k,c| ", :#{k}=>list_params[:#{k}]"}.join+"}).to_s << '"

        code = "(#{table.records_variable_name}.total_pages > 1 ? '<tfoot><tr><th colspan=\"#{table.columns.size+1}\">#{pagination}</th></tr></tfoot>' : '').html_safe"
      end

      code = "''" if code.blank?
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
      column_sort = "\#\{' sor' if list_params[:sort]=='#{column.id}'\}" if column.sortable?
      column_sort << "\#\{' hidden' if list_params[:hidden_columns].include?('#{column.id}')\}" if column.is_a? DataColumn
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


List.register_renderer(:simple_renderer, List::SimpleRenderer)
