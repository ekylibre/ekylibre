# coding: utf-8
# Dyta
module Ekylibre
  module Dyke
    module Dyta
      @@will_paginate = false
      @@will_paginate = true if defined? WillPaginate
      mattr_accessor :will_paginate

      @@list_method_suffix = '_dyta'
      @@tag_method_suffix = @@list_method_suffix+'_tag'
      mattr_accessor :list_method_suffix
      mattr_accessor :tag_method_suffix
      

      class InvalidName < ArgumentError
        def initialize(name)
          super "#{name} is a name already used or unusable"
        end
      end


      module Controller

        def self.included(base) #:nodoc:
          base.extend(ClassMethods)
        end

        module ClassMethods

          PAGINATION = {
            :will_paginate=>{
              :find_method=>'paginate',
              :find_params=>':page=>page, :per_page=>@@LENGTH@@'
            },
            :none=>{
              :find_method=>'find',
              :find_params=>''
            }
          }
          
          OPTIONS = [:model, :distinct, :conditions, :order, :joins, :empty, :per_page, :pagination, :export, :children, :line_class]

          # Add methods to display a dynamic table
          def dyta(name, new_options={}, &block)
            name = name.to_s
            # Don't forget the View module if you change the names
            list_method_name = name+Ekylibre::Dyke::Dyta.list_method_suffix
            tag_method_name  = name+Ekylibre::Dyke::Dyta.tag_method_suffix

            if ActionView::Base.public_instance_methods.include? tag_method_name
              if RAILS_ENV == 'production'
                raise InvalidName.new(name)
                return
              end
            end


            options = {:pagination=>:none, :empty=>false, :export=>'dyta.export'}
            options[:pagination] = :will_paginate if Ekylibre::Dyke::Dyta.will_paginate
            options.merge! new_options

            options.keys.each do |k|
              raise ArgumentError.new("Unvalid option for the dyta :#{name} (#{k.inspect})") unless OPTIONS.include?(k)
            end


            model = (options[:model]||name).to_s.classify.constantize
            begin
              model.columns_hash["id"]
            rescue
              return
            end
            definition = Dyta.new(name, model, options)
            yield definition



            if options[:pagination] == :will_paginate and not options.keys.include?(:order)
              cols = definition.table_columns
              if cols.size > 0
                options[:order] = '"'+cols[0].name.to_s+'"'
              else
                raise ArgumentError.new("Option :order is needed for the dyta :#{name}")
              end
            end


            code = ""

            # List method
            conditions = ''
            conditions = conditions_to_code(options[:conditions]) if options[:conditions]

            default_order = (options[:order] ? '||'+options[:order].inspect : '')

            order_definition  = ''
            order_definition += "  options = (params||{}).merge(options||{})\n"
            order_definition += "  session[:dyta] ||= {}\n"
            order_definition += "  session[:dyta][:#{name}] ||= {}\n"
            order_definition += "  page = (options[:page]||session[:dyta][:#{name}][:page]||1).to_i\n"
            order_definition += "  session[:dyta][:#{name}][:page] = page\n"
            order_definition += "  order = nil\n"
            order_definition += "  options['#{name}_sort'] ||= session[:dyta][:#{name}][:sort]\n"
            order_definition += "  options['#{name}_dir']  ||= session[:dyta][:#{name}][:dir]\n"
            order_definition += "  unless options['#{name}_sort'].blank?\n"
            order_definition += "    options['#{name}_dir'] ||= 'asc'\n"
            order_definition += "    order  = ActiveRecord::Base.connection.quote_column_name(options['#{name}_sort'])\n"
            order_definition += "    order += options['#{name}_dir']=='desc' ? ' DESC' : ' ASC'\n"
            order_definition += "  end\n"
            order_definition += "  session[:dyta][:#{name}][:sort] = options['#{name}_sort']\n"
            order_definition += "  session[:dyta][:#{name}][:dir]  = options['#{name}_dir']\n"


            builder  = order_definition
            builder += "  @#{name}=#{model}."+PAGINATION[options[:pagination]][:find_method]+"(:all"
            builder += ", :select=>'DISTINCT #{model.table_name}.*'" if options[:distinct]
            builder += ", :conditions=>"+conditions unless conditions.blank?
            builder += ", "+PAGINATION[options[:pagination]][:find_params].gsub('@@LENGTH@@', "options['#{name}_per_page']||"+(options[:per_page]||25).to_s) unless PAGINATION[options[:pagination]][:find_params].blank?
            builder += ", :joins=>#{options[:joins].inspect}" unless options[:joins].blank?
            builder += ", :order=>order#{default_order})||{}\n"
            if options[:pagination] == :will_paginate
              builder += "  return #{tag_method_name}(options.merge(:page=>1)) if page>1 and @#{name}.out_of_bounds?\n"
            end

            footer_var = 'footer'
            footer = "#{footer_var}=''\n"
            # Export link
            if options[:export]
              # footer += footer_var+"+='"+content_tag(:div, "'+link_to('"+::I18n.translate(options[:export]).gsub(/\'/,'&#39;')+"', {:action=>:#{list_method_name}, '#{name}_sort'=>params['#{name}_sort'], '#{name}_dir'=>params['#{name}_dir'], :format=>'csv'}, {:method=>:post})+'", :class=>'export')+"'\n"
              
              export = "content_tag(:span, ::I18n.translate('#{options[:export]}.title'))"
              for format in [:csv, :xcsv]
                # export += "+' '+link_to(::I18n.translate('#{options[:export]}.#{format}').gsub(/\'/,'&#39;'), {:action=>:#{list_method_name}, '#{name}_sort'=>params['#{name}_sort'], '#{name}_dir'=>params['#{name}_dir'], :format=>'#{format}'}, {:method=>:post})"
                export += "+' '+link_to(::I18n.translate('#{options[:export]}.#{format}').gsub(/\'/,'&#39;'), {:action=>:#{list_method_name}, '#{name}_sort'=>params['#{name}_sort'], '#{name}_dir'=>params['#{name}_dir'], :format=>'#{format}'})"
              end
              footer += footer_var+"+=content_tag(:div, #{export}, :class=>'export')\n"
            end
            # Pages link
            footer += if options[:pagination] == :will_paginate
                        footer_var+"+=will_paginate(@"+name.to_s+", :previous_label => ::I18n.translate('dyta.previous'), :next_label => ::I18n.translate('dyta.next'), :renderer=>ActionView::RemoteLinkRenderer, :remote=>{:update=>'"+name.to_s+"', :loading=>'onLoading();', :loaded=>'onLoaded();'}, :params=>{'#{name}_sort'=>params['#{name}_sort'], '#{name}_dir'=>params['#{name}_dir'], '#{name}_per_page'=>params['#{name}_per_page'], :action=>:#{list_method_name}}).to_s\n"
                        # footer_var+"='"+content_tag(:tr, content_tag(:td, "'+"+footer_var+"+'", :class=>:paginate, :colspan=>definition.columns.size))+"' unless "+footer_var+".nil?\n"
                      else
                        ''
                      end

            # Footer tag
            footer += footer_var+"='"+content_tag(:tr, content_tag(:th, "'+"+footer_var+"+'", :class=>:footer, :colspan=>definition.columns.size))+"' unless body.blank? "+(options[:export] ? "" : " or "+footer_var+".blank?")+"\n"

            #if options[:order].nil?
            sorter  = "    sort = options['#{name}_sort']\n"
            sorter += "    dir = options['#{name}_dir']\n"
            #else
            #  sorter  = "    sort = #{options[:order]['sort'].to_s.inspect}\n"
            #  sorter += "    dir = #{(options[:order]['dir']||'asc').to_s.inspect}\n"
            #end

            record = 'r'
            child  = 'c'


            code += "def #{list_method_name}\n"
            code += "  if request.xhr?\n"
            code += "    render(:inline=>'<%=#{tag_method_name}-%>')\n" # 
            if options[:export]
              code += "  elsif request.get? and params[:format]\n"
              code += order_definition.gsub(/^/,'  ')
              code += "    if params[:format] == 'xcsv'\n"
              code += "      ic = Iconv.new('cp1252', 'utf-8')\n"
              code += "      data = FasterCSV.generate(:col_sep=>';') do |csv|\n"
              code += "        csv << #{columns_to_csv(definition, :header, :iconv=>'ic')}\n"
              code += "        for #{record} in #{model}.find(:all"
              code += ", :conditions=>"+conditions unless conditions.blank?
              code += ", :joins=>#{options[:joins].inspect}" unless options[:joins].blank?
              code += ", :order=>order#{default_order})||{}\n"            
              code += "          csv << #{columns_to_csv(definition, :body, :record=>record, :iconv=>'ic')}\n"
              code += "        end\n"
              code += "      end\n"
              code += "    else\n"
              code += "      data = FasterCSV.generate do |csv|\n"
              code += "        csv << #{columns_to_csv(definition, :header)}\n"
              code += "        for #{record} in #{model}.find(:all"
              code += ", :conditions=>"+conditions unless conditions.blank?
              code += ", :joins=>#{options[:joins].inspect}" unless options[:joins].blank?
              code += ", :order=>order#{default_order})||{}\n"            
              code += "          csv << #{columns_to_csv(definition, :body, :record=>record)}\n"
              code += "        end\n"
              code += "      end\n"
              code += "    end\n"
              code += "    send_data(data, :type=>Mime::CSV, :disposition=>'inline', :filename=>#{model.name}.model_name.human.gsub(/[^a-z0-9]/i,'_')+'.csv')\n"
            end
            code += "  elsif request.get?\n"
            code += "    render(:inline=>'<%=#{tag_method_name}-%>', :layout=>true)\n"
            code += "  end\n"
            code += "end\n"
            
            # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}

            module_eval(code)

            
            header = columns_to_td(definition, :header, :method=>list_method_name, :id=>name)
            body = columns_to_td(definition, :body, :record=>record)
            if options[:children].is_a? Symbol
              children = options[:children].to_s
              child_body = columns_to_td(definition, :children, :record=>child, :order=>options[:order])
            end          

            header = 'content_tag(:tr, ('+header+').html_safe, :class=>"header")'

            code  = "def #{tag_method_name}(options={})\n"
            code += builder
            code += "  if @"+name.to_s+".size>0\n"
            code += sorter
            code += "    header = "+header+"\n"
            code += "    reset_cycle('dyta')\n"
            code += "    body = ''\n"
            code += "    for #{record} in @"+name.to_s+"\n"
            code += "      line_class = ' '+"+options[:line_class].to_s.gsub(/RECORD/,record)+".to_s\n" unless options[:line_class].nil?
            code += "      line_style = ' '+"+options[:line_style].to_s.gsub(/RECORD/,record)+".to_s\n" unless options[:line_style].nil?
            opt_line_class = (options[:line_class].nil? ? '' : "+line_class")
            opt_line_style = (options[:line_style].nil? ? '' : "+line_style")
            code += "      body += content_tag(:tr, ("+body+").html_safe, :class=>'data '+cycle('odd','even', :name=>'dyta')"+opt_line_class+opt_line_style+")\n"
            if children
              code += "      for #{child} in #{record}.#{children}\n"
              code += "        body += content_tag(:tr, ("+child_body+").html_safe, :class=>'data child '+cycle('odd','even', :name=>'dyta')"+opt_line_class+opt_line_style+")\n"
              code += "      end\n"
            end
            code += "    end\n"
            code += footer.gsub(/^/, '    ')
            code += "    text = content_tag(:thead, header.html_safe)+content_tag(:tfoot, #{footer_var}.html_safe)+content_tag(:tbody, body.html_safe)\n"
            code += "  else\n"
            if options[:empty]
              code += "    text = ''\n"
            else
              code += "    text = content_tag(:thead, "+header+")+('<tr class=\"empty\"><td colspan=\"#{definition.columns.size}\">'+::I18n.translate('dyta.no_records')+'</td></tr>').html_safe\n"
            end
            code += "  end\n"
            code += footer;
            # code += "  text = content_tag(:table, text, :class=>:dyta, :id=>'"+name.to_s+"') unless request.xhr?\n"
            code += "  text = content_tag(:table, text.html_safe, :class=>:dyta)\n"
            code += "  text = content_tag(:div, text.html_safe, :class=>:dyta, :id=>'"+name.to_s+"') unless request.xhr?\n"
            code += "  return text\n"
            code += "end\n"
            
            # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
            
            ActionView::Base.send :class_eval, code

          end

          def columns_to_td(definition, nature, options={})
            columns = definition.columns
            code = ''
            record = options[:record]||'RECORD'
            list_method_name = options[:method]||'dyta_list'
            for column in columns
              column_sort = ''
              if column.sortable?
                column_sort = "\#\{' sorted' if sort=='#{column.name}'\}"
              end
              if nature==:header
                code += "+\n      " unless code.blank?
                header_title = column.compile_header
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
                    code += "hidden_field_tag('#{definition.name}['+#{record}.id.to_s+'][#{column.name}]', 0, :id=>nil)+"
                    code += "check_box_tag('#{definition.name}['+#{record}.id.to_s+'][#{column.name}]', 1, #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{definition.name}_'+#{record}.id.to_s+'_#{column.name}')"
                  else
                    code += "''"
                  end
                  code += ", :class=>'chk')"
                when :textbox
                  code += "content_tag(:td,"
                  if nature==:body 
                    code += "text_field_tag('#{definition.name}['+#{record}.id.to_s+'][#{column.name}]', #{column.options[:value] ? column.options[:value].to_s.gsub(/RECORD/, record) : record+'.'+column.name.to_s}, :id=>'#{definition.name}_'+#{record}.id.to_s+'_#{column.name}'#{column.options[:size] ? ', :size=>'+column.options[:size].to_s : ''})"
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

           
            code
          end


          def columns_to_csv(definition, nature, options={})
            columns = definition.columns

            array = []
            record = options[:record]||'RECORD'
            for column in columns
              if column.nature==:column
                if nature==:header
                  datum = column.compile_header
                else
                  datum = column.data(record)
                  if column.datatype == :boolean
                    datum = "(#{datum} ? ::I18n.translate('dyta.export.true_value') : ::I18n.translate('dyta.export.false_value'))"
                  end
                  if column.datatype == :date
                    datum = "::I18n.localize(#{datum})"
                  end
                  if column.datatype == :decimal
                    datum = "(#{datum}.nil? ? '' : number_to_currency(#{datum}, :separator=>',', :delimiter=>'', :unit=>'', :precision=>#{column.options[:precision]||2}))"
                  end
                  if column.name==:country and  column.datatype == :string and column.limit == 2
                    datum = "(#{datum}.nil? ? '' : ::I18n.translate('countries.'+#{datum}))"
                  end
                  if column.name==:language and  column.datatype == :string and column.limit <= 8
                    datum = "(#{datum}.nil? ? '' : ::I18n.translate('languages.'+#{datum}))"
                  end
                end
                array << (options[:iconv] ? "#{options[:iconv]}.iconv("+datum+".to_s)" : datum)
              end
            end
            return '['+array.join(', ')+']'
          end




          # Generate the code from a conditions option
          def conditions_to_code(conditions)
            code = ''
            case conditions
            when Array
              case conditions[0]
              when String  # SQL
                code += '["'+conditions[0].to_s+'"'
                code += ', '+conditions[1..-1].collect{|p| sanitize_conditions(p)}.join(', ') if conditions.size>1
                code += ']'
              when Symbol # Method
                code += conditions[0].to_s+'('
                code += conditions[1..-1].collect{|p| sanitize_conditions(p)}.join(', ') if conditions.size>1
                code += ')'
              else
                raise Exception.new("First element of an Array can only be String or Symbol.")
              end
            when Hash # SQL
              code += '{'+conditions.collect{|key, value| ':'+key.to_s+'=>'+sanitize_conditions(value)}.join(',')+'}'
            when Symbol # Method
              code += conditions.to_s+"(options)"
            when String
              code += "("+conditions.gsub(/\s*\n\s*/,';')+")"
            else
              raise Exception.new("Unsupported type for :conditions: #{conditions.inspect}")
            end
            code
          end



          def sanitize_conditions(value)
            if value.is_a? Array
              if value.size==1 and value[0].is_a? String
                value[0].to_s
              else
                value.inspect
              end
            elsif value.is_a? String
              '"'+value.gsub('"','\"')+'"'
            elsif [Date, DateTime].include? value.class
              '"'+value.to_formatted_s(:db)+'"'
            elsif value.is_a? NilClass
              'nil'
            else
              value.to_s
            end
          end

        end  

      end





      # Dyta represents a DYnamic TAble
      class Dyta
        attr_reader :name, :model, :options
        attr_reader :columns # , :procedures
        
        def initialize(name, model, options)
          @name    = name
          @model   = model
          @options = options
          @columns = []
          @procedures = []
        end

        def table_columns
          cols = @model.columns.collect{|c| c.name}
          @columns.select{|c| c.nature == :column and cols.include? c.name.to_s}
        end

        
        def column(name, options={})
          @columns << DytaElement.new(model, :column, name, options)
        end
        
        def action(name, options={})
          @columns << DytaElement.new(model, :action, name, options)
        end
        
        def check(name=:validated, options={})
          @columns << DytaElement.new(model, :check, name, options)
        end
        
        def textbox(name=:name, options={})
          @columns << DytaElement.new(model, :textbox, name, options)
        end
        
      end


      # Dyta Element represents an element of a Dyta
      class DytaElement
        attr_accessor :name, :options
        attr_reader :nature
        include ERB::Util

        def initialize(model, nature, name, options={})
          @model   = model
          @nature  = nature
          @name    = name
          @options = options
          @column  = @model.columns_hash[@name.to_s] if @nature == :column
        end

        def action?
          @nature == :action
        end

        def sortable?
          not self.action? and not self.options[:through] and not @column.nil?
        end

#         def header
#           if @options[:label].blank?
#             case @nature
#             when :column
#               if @options[:through] and @options[:through].is_a?(Symbol)
#                 reflection = @model.reflections[@options[:through]]
#                 raise Exception.new("Unknown reflection :#{@options[:through].to_s} for the ActiveRecord: "+@model.to_s) if reflection.nil?
#                 # # @model.columns_hash[@model.reflections[@options[:through]].primary_key_name].human_name
#                 if reflection.macro == :has_one
#                   ::I18n.translate("activerecord.attributes.#{reflection.class_name.underscore}.#{@name}")
#                 else
#                   ::I18n.translate("activerecord.attributes.#{@model.to_s.tableize.singularize}.#{@model.reflections[@options[:through]].primary_key_name.to_s}")
#                 end
#               elsif @options[:through] and @options[:through].is_a?(Array)
#                 model = @model
#                 (@options[:through].size-1).times do |x|
#                   model = model.reflections[@options[:through][x]].options[:class_name].constantize
#                 end
#                 reflection = @options[:through][@options[:through].size-1].to_sym
#                 model.columns_hash[model.reflections[reflection].primary_key_name].human_name
#               else
#                 @model.human_attribute_name(@name.to_s)
#               end;
#             when :action
#               'ƒ'
#             when :check, :textbox then
#               @model.human_attribute_name(@name.to_s)
#             else 
#               '-'
#             end
#           else
#             @options[:label].to_s
#           end
#         end



        def compile_header
          case @nature
          when :column
            if @options[:through] and @options[:through].is_a?(Symbol)
              reflection = @model.reflections[@options[:through]]
              raise Exception.new("Unknown reflection :#{@options[:through].to_s} for the ActiveRecord: "+@model.to_s) if reflection.nil?
              if @options[:label].is_a? String
                "::I18n.translate('labels.#{@options[:label].strip}')"
              elsif reflection.macro == :has_one or @options[:label] == :column
                "#{reflection.class_name}.human_attribute_name('#{@name}')"
              else
                "#{@model.name}.human_attribute_name(#{@options[:through].to_s.inspect})"
              end
            elsif @options[:through] and @options[:through].is_a?(Array)
              model = @model
              (@options[:through].size-1).times do |x|
                model = model.reflections[@options[:through][x]].options[:class_name].constantize
              end
              reflection = @options[:through][@options[:through].size-1].to_sym
              # model.columns_hash[model.reflections[reflection].primary_key_name].human_name
              # "#{model.name}.human_attribute_name('#{model.reflections[reflection].primary_key_name}')"
              "::I18n.translate('activerecord.attributes.#{model.name.underscore}.#{model.reflections[reflection].primary_key_name}')"
            else
              "#{@model.name}.human_attribute_name('#{@name}')"
            end;
          when :action
            "'ƒ'"
          when :check, :textbox then
            "#{@model.name}.human_attribute_name('#{@name}')"
          else 
            "'-'"
          end
        end






        
        def limit
          @column.limit if @column
        end

        def datatype
          @options[:datatype] || (@column ? @column.type : nil)
        end

        def data(record='record', child = false)
          code = if child and @options[:children].is_a? Symbol
                   record+'.'+@options[:children].to_s
                 elsif child and @options[:children].is_a? FalseClass
                   'nil'
                 elsif @options[:through] and !child
                   through = [@options[:through]] unless @options[:through].is_a?(Array)
                   foreign_record = record
                   through.size.times { |x| foreign_record += '.'+through[x].to_s }
                   '('+foreign_record+'.nil? ? nil : '+foreign_record+'.'+@name.to_s+')'
                 else
                   record+'.'+@name.to_s
                 end
          code
        end

        def record(record='record')
          if @options[:through]
            through = [@options[:through]] unless @options[:through].is_a?(Array)
            foreign_record = record
            through.size.times { |x| foreign_record += '.'+through[x].to_s }
            foreign_record
          else
            record
          end
        end

        def operation(record='record')
          link_options = ""
          link_options += ", :confirm=>::I18n.translate('labels.#{@options[:confirm]}')" unless @options[:confirm].nil?
          link_options += ", :method=>#{@options[:method].inspect}" if @options[:method].is_a? Symbol
          verb = @name.to_s.split('_')[-1]
          image_title = @options[:title]||@name.to_s.humanize
          # image_file = "buttons/"+(@options[:image]||verb).to_s+".png"
          # image_file = "buttons/unknown.png" unless File.file? "#{Rails.root.to_s}/public/images/"+image_file
          image = "image_tag(theme_button('#{@options[:image]||verb}'), :alt=>'"+image_title+"')"
          format = @options[:format] ? ", :format=>'#{@options[:format]}'" : ""
          if @options[:remote] 
            remote_options = @options.dup
            remote_options[:confirm] = ::I18n.translate('labels.'+@options[:confirm].to_s) unless @options[:confirm].nil?
            remote_options.delete :remote
            remote_options.delete :image
            remote_options = remote_options.inspect.to_s
            remote_options = remote_options[1..-2]
            code  = "link_to_remote(#{image}"
            code += ", {:url=>{:action=>:"+@name.to_s+", :id=>"+record+".id"+format+"}"
            code += ", "+remote_options+"}"
            code += ", {:title=>::I18n.translate('labels.#{verb}')}"
            code += ")"
          elsif @options[:actions]
            raise Exception.new("options[:actions] have to be a Hash.") unless @options[:actions].is_a? Hash
            cases = []
            for a in @options[:actions]
              v = a[1][:action].to_s.split('_')[-1]
              cases << record+"."+@name.to_s+".to_s=="+a[0].inspect+"\nlink_to(image_tag(theme_button('#{v}'), :alt=>'"+a[0].to_s+"')"+
                ", {"+(a[1][:controller] ? ':controller=>:'+a[1][:controller].to_s+', ' : '')+":action=>'"+a[1][:action].to_s+"', :id=>"+record+".id"+format+"}"+
                ", {:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+link_options+", :title=>::I18n.translate('labels.#{v}')}"+
                ")\n"
            end

            code = "if "+cases.join("elsif ")+"end"
          else
            url = @options[:url] ||= {}
            url[:controller] ||= @options[:controller]
            url[:action] ||= @name
            url[:id] ||= "RECORD.id"
            url.delete_if{|k, v| v.nil?}
            url = "{"+url.collect{|k, v| ":#{k}=>"+(v.is_a?(String) ? v.gsub(/RECORD/, record) : v.inspect)}.join(", ")+format+"}"
            code = "{:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+link_options+", :title=>::I18n.translate('labels.#{verb}')}"
            code = "link_to("+image+", "+url+", "+code+")"
          end
          code = "if ("+@options[:if].gsub('RECORD', record)+")\n"+code+"\n end" if @options[:if]
          code
        end
        


      end


      module View
        def dyta(name)
          self.send(name.to_s+Ekylibre::Dyke::Dyta.tag_method_suffix)
        end
      end

    end

  end
end





if Ekylibre::Dyke::Dyta.will_paginate

  # raise Exception.new WillPaginate.methods.sort.to_sentence

  ERB::Util::HTML_ESCAPE.merge( '&' => '&#38;', '>' => '&#62;', '<' => '&#60;', '"' => '&#34;' )

  module ActionView
    class RemoteLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
      
      def initialize
        @gap_marker = '<span class="gap">&#8230;</span>'
      end

      def prepare(collection, options, template)
        @remote = options.delete(:remote) || {}
        super
      end

      protected

      # WillPaginate 2
      def page_link(page, text, attributes = {})
        @template.link_to_remote(text, {:url => url_for(page), :method => :get}.merge(@remote), attributes)
      end

      # WillPaginate 3
      def link(text, target, attributes = {})
        if target.is_a? Fixnum
          attributes[:rel] = rel_value(target)
          target = url(target)
        end
        attributes[:href] = target
        @template.link_to_remote(text, {:url => target, :method => :get}.merge(@remote), attributes)
      end

    end  
  end

#   include WillPaginate::ViewHelpers 
#   def will_paginate_with_i18n(collection, options = {}) 
#     will_paginate_without_i18n(collection, options.merge(:previous_label => ::I18n.t("dyta.previous"), :next_label => ::I18n.t("dyta.next")))
#   end 
#   alias_method_chain :will_paginate, :i18n  


end
