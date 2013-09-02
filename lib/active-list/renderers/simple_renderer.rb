module ActiveList

  class SimpleRenderer < ActiveList::Renderer

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
      code << "  head :ok\n"
      code << "elsif params[:only]\n"
      code << "  render(:inline=>'<%=#{table.view_method_name}(:only => params[:only])-%>')\n" 
      code << "else\n"
      code << "  render(:inline=>'<%=#{table.view_method_name}-%>')\n" 
      code << "end\n"
      return code
    end

    def build_table_code(table)
      record = "r"
      child  = "c"

      colgroup = columns_definition_code(table)
      header = header_code(table)
      extras = extras_code(table)
      tbody = columns_to_cells(table, :body, :record=>record)

      code  = table.select_data_code
      code << "tbody = '<tbody data-total=\"'+#{table.records_variable_name}_count.to_s+'\""
      if table.paginate?
        code << " data-per-page=\"'+#{table.records_variable_name}_limit.to_s+'\""
        code << " data-pages-count=\"'+#{table.records_variable_name}_last.to_s+'\""
        # code << " data-page-label=\"'+::I18n.translate('list.pagination.showing_x_to_y_of_total', :x => (#{table.records_variable_name}_offset + 1), :y => (#{table.records_variable_name}_offset+#{table.records_variable_name}_limit), :total => #{table.records_variable_name}_count)+'\""
      end
      code << ">'\n"
      code << "if #{table.records_variable_name}_count > 0\n"
      code << "  reset_cycle('list')\n"
      code << "  for #{record} in #{table.records_variable_name}\n"
      line_class = "cycle('odd', 'even', :name=>'list')+' r'+#{record}.id.to_s"
      line_class << "+' '+("+table.options[:line_class].to_s.gsub(/RECORD/, record)+').to_s' unless table.options[:line_class].nil?
      code << "    tbody << content_tag(:tr, (#{tbody}).html_safe, :class=>#{line_class})\n"
      if table.options[:children].is_a? Symbol
        children = table.options[:children].to_s
        child_tbody = columns_to_cells(table, :children, :record=>child)
        code << "    for #{child} in #{record}.#{children}\n"
        code << "      tbody << content_tag(:tr, (#{child_tbody}).html_safe, {:class=>#{line_class}+' child'})\n"
        code << "    end\n"
      end
      code << "  end\n"
      code << "else\n"
      code << "  tbody << '<tr class=\"empty\"><td colspan=\"#{table.columns.size+1}\">' + ::I18n.translate('list.no_records') + '</td></tr>'\n"
      code << "end\n"
      code << "tbody << '</tbody>'\n"
      code << "return tbody.html_safe if options[:only] == 'body' or options[:only] == 'tbody'\n"

      code << "html = ''\n"
      code << "html << '<div id=\"#{table.name}\" data-list-source=\"'+h(url_for(options.merge(:action => '#{table.controller_method_name}')))+'\" class=\"active-list\""
      code << " data-list-current-page=\"' + #{table.records_variable_name}_page.to_s + '\" data-list-page-size=\"' + #{table.records_variable_name}_limit.to_s + '\""
      code << " data-list-sort-by=\"' + list_params[:sort].to_s + '\" data-list-sort-dir=\"' + list_params[:dir].to_s + '\""
      code << ">'\n"
      code << "html << '<table class=\"list\">'\n"
      code << "html << (#{header})\n"
      code << "if block_given?\n"
      code << "  html << '<tfoot>'+capture("+table.columns.collect{|c| {:name=>c.name, :id=>c.id}}.inspect+", &block)+'</tfoot>'\n"
      code << "end\n"
      code << "html << tbody\n"
      code << "html << '</table>'\n"
      code << "html << #{extras}\n" if extras
      code << "html << '</div>'\n"
      code << "return html.html_safe\n"
      return code
    end



    def columns_to_cells(table, nature, options={})
      columns = table.columns
      code = ''
      record = options[:record]||'RECORD'
      for column in columns
        if nature==:header
          raise Exception.new("Ohohoh")
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
                datum = "(#{datum}.nil? ? '' : ::I18n.localize(#{datum}, :currency => #{currency}))"
              elsif column.datatype == :decimal
                datum = "(#{datum}.nil? ? '' : ::I18n.localize(#{datum}))"
              elsif column.enumerize?
                datum = "(#{datum}.nil? ? '' : #{datum}.text)"                
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
                datum = "(#{datum}.blank? ? '' : ::I18n.currency_label(#{datum}))"
              elsif column.name==:language and column.datatype == :string and column.limit <= 8
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
      if table.paginate?
        # Per page
        list = [5, 10, 20, 50, 100, 200]
        list << table.options[:per_page].to_i if table.options[:per_page].to_i > 0
        list = list.uniq.sort
        menu << "<li class=\"parent\">"
        menu << "<a class=\"pages\"><span class=\"icon\"></span><span class=\"text\">' + ::I18n.translate('list.items_per_page').gsub(/\'/,'&#39;') + '</span></a><ul>"
        for n in list
          menu << "<li data-list-change-page-size=\"#{n}\" '+(list_params[:per_page] == #{n} ? ' class=\"check\"' : '')+'><a><span class=\"icon\"></span><span class=\"text\">'+h(::I18n.translate('list.x_per_page', :count=>#{n}))+'</span></a></li>"
        end
        menu << "</ul></li>"
      end

      # Column selector
      menu << "<li class=\"parent\">"
      menu << "<a class=\"columns\"><span class=\"icon\"></span><span class=\"text\">' + ::I18n.translate('list.columns').gsub(/\'/,'&#39;') + '</span></a><ul>"
      for column in table.data_columns
        menu << "<li data-list-toggle-column=\"#{column.id}\" class=\"'+(list_params[:hidden_columns].include?('#{column.id}') ? 'unchecked' : 'checked')+'\"><a><span class=\"icon\"></span><span class=\"text\">'+h(#{column.header_code})+'</span></a></li>"
      end
      menu << "</ul></li>"

      # Separator
      menu << "<li class=\"separator\"></li>"      
      # Exports
      for format, exporter in ActiveList.exporters
        menu << "<li class=\"export #{exporter.name}\">' + link_to(params.merge(:action=>:#{table.controller_method_name}, :sort=>list_params[:sort], :dir=>list_params[:dir], :format=>'#{format}')) { '<span class=\"icon\"></span>'.html_safe + content_tag('span', ::I18n.translate('list.export_as', :exported=>::I18n.translate('list.export.formats.#{format}')).gsub(/\'/,'&#39;'), :class=>'text')} + '</li>"
      end
      menu << "</ul></div>"
      return menu
    end

    # Produces the code to create the header line using  top-end menu for columns
    # and pagination management
    def header_code(table)
      code = "'<thead><tr>"
      for column in table.columns
        code << "<th data-list-column=\"#{column.id}\""
        code << " data-list-column-cells=\"#{column.simple_id}\""
        code << " data-list-column-sort=\"'+(list_params[:sort]!='#{column.id}' ? 'asc' : list_params[:dir] == 'asc' ? 'desc' : 'asc')+'\"" if column.sortable?
        code << " class=\"#{column_classes(column, true, true)}\""
        code << ">"
        code << "<span class=\"text\">'+h(#{column.header_code})+'</span>"
        code << "<span class=\"icon\"></span>"
        code << "</th>"
      end
      code << "<th class=\"spe\">#{menu_code(table)}</th>"
      code << "</tr></thead>'"
      return code
    end

    # Produces the code to create bottom menu and pagination
    def extras_code(table)
      code, pagination = nil, ''

      if table.paginate?
        current_page = "#{table.records_variable_name}_page"
        last_page = "#{table.records_variable_name}_last"

        pagination << "<div class=\"pagination\">"
        pagination << "<a href=\"#\" data-list-move-to-page=\"1\" class=\"first-page\"' + (#{current_page} != 1 ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.first') + '</a>"
        pagination << "<a href=\"#\" data-list-move-to-page=\"' + (#{current_page} - 1).to_s + '\" class=\"previous-page\"' + (#{current_page} != 1 ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.previous') + '</a>"

        x = '@@PAGE-NUMBER@@'
        y = '@@PAGE-COUNT@@'
        pagination << "<span class=\"paginator\">'+::I18n.translate('list.page_x_on_y', :default=>'%{x} / %{y}', :x => '#{x}', :y =>'#{y}').html_safe.gsub('#{x}', ('<input type=\"number\" size=\"4\" data-list-move-to-page=\"value\" value=\"'+#{table.records_variable_name}_page.to_s+'\">').html_safe).gsub('#{y}', #{table.records_variable_name}_last.to_s) + '</span>"

        pagination << "<a href=\"#\" data-list-move-to-page=\"' + (#{current_page} + 1).to_s + '\" class=\"next-page\"' + (#{current_page} != #{last_page} ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.next')+'</a>"
        pagination << "<a href=\"#\" data-list-move-to-page=\"' + (#{last_page}).to_s + '\" class=\"last-page\"' + (#{current_page} != #{last_page} ? '' : ' disabled=\"true\"') + '><i></i>' + ::I18n.translate('list.pagination.last')+'</a>"

        pagination << "<span class=\"separator\"></span>"

        pagination << "<span class=\"status\">'+::I18n.translate('list.pagination.showing_x_to_y_of_total', :x => (#{table.records_variable_name}_offset + 1), :y => ((#{table.records_variable_name}_last==#{table.records_variable_name}_page) ? #{table.records_variable_name}_count : #{table.records_variable_name}_offset+#{table.records_variable_name}_limit), :total => #{table.records_variable_name}_count)+'</span>"
        pagination << "</div>"

        code = "(#{table.records_variable_name}_last > 1 ? '<div class=\"extras\">#{pagination}</div>' : '').html_safe"
      end

      return code
    end

    # Not used
    def columns_definition_code(table)
      code = table.columns.collect do |column|
        "<col id=\\\"#{column.unique_id}\\\" class=\\\"#{column_classes(column, true)}\\\" data-cells-class=\\\"#{column.simple_id}\\\" href=\\\"\#\{url_for(:action=>:#{table.controller_method_name}, :column=>#{column.id.to_s.inspect})\}\\\" />"
      end.join
      return "\"#{code}\""
    end

    # Finds all default styles for column
    def column_classes(column, without_id=false, without_interpolation=false)
      classes, conds = [], []
      conds << [:sor, "list_params[:sort]=='#{column.id}'"] if column.sortable?
      conds << [:hidden, "list_params[:hidden_columns].include?('#{column.id}')"] if column.is_a? DataColumn
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
      else
        classes << :unk
      end
      html = classes.join(' ').strip
      if conds.size > 0
        if without_interpolation
          html << "' + "
          html << conds.collect do |c|
            "(#{c[1]} ? ' #{c[0]}' : '')"
          end.join(' + ')
          html << " + '"
        else
          html << conds.collect do |c|
            "\#\{' #{c[0]}' if #{c[1]}\}"
          end.join
        end
      end
      return html
    end


  end
  

end


ActiveList.register_renderer(:simple_renderer, ActiveList::SimpleRenderer)
