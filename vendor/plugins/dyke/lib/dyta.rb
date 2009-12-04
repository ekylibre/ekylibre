# Dyta
module Ekylibre
  module Dyke
    module Dyta
      mattr_accessor :will_paginate
      @@will_paginate = false
      @@will_paginate = true if defined? WillPaginate

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
            :default=>{
              :find_method=>'find',
              :find_params=>''
            }
          }
          
          OPTIONS = [:model, :distinct, :conditions, :order, :joins, :empty, :per_page, :pagination, :export, :children, :line_class]

          # Add methods to display a dynamic table
          def dyta(name, new_options={}, &block)
            name = name.to_s
            # Don't forget the View module if you change the names
            list_method_name = name+'_dyta'
            tag_method_name  = list_method_name+'_tag'

            if ActionView::Base.public_instance_methods.include? tag_method_name
              if RAILS_ENV == 'production'
                raise InvalidName.new(name)
                return
              end
            end


            options = {:pagination=>:default, :empty=>true, :export=>'general.export'}
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
                options[:order] = '"'+cols[0].name+'"'
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
            order_definition += "    order  = options['#{name}_sort']\n"
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
              footer += footer_var+"+='"+content_tag(:div, "'+link_to('"+::I18n.t(options[:export]).gsub(/\'/,'&apos;')+"', {:action=>:#{list_method_name}, '#{name}_sort'=>params['#{name}_sort'], '#{name}_dir'=>params['#{name}_dir'], :format=>'csv'}, {:method=>:post})+'", :class=>'export')+"'\n"
            end
            # Pages link
            footer += if options[:pagination] == :will_paginate
                        footer_var+"+=will_paginate(@"+name.to_s+", :renderer=>ActionController::RemoteLinkRenderer, :remote=>{:update=>'"+name.to_s+"', :loading=>'onLoading();', :loaded=>'onLoaded();'}, :params=>{'#{name}_sort'=>params['#{name}_sort'], '#{name}_dir'=>params['#{name}_dir'], '#{name}_per_page'=>params['#{name}_per_page'], :action=>:#{list_method_name}}).to_s\n"
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
            code += "    render(:inline=>'<%=#{tag_method_name}-%>')\n"
            if options[:export]
              code += "  elsif request.post?\n"
              code += order_definition.gsub(/^/,'  ')
              code += "    data = FasterCSV.generate do |csv|\n"
              code += "      csv << #{columns_to_csv(definition, :header)}\n"
              code += "      for #{record} in #{model}.find(:all"
              code += ", :conditions=>"+conditions unless conditions.blank?
              code += ", :joins=>#{options[:joins].inspect}" unless options[:joins].blank?
              code += ", :order=>order#{default_order})||{}\n"            
              code += "        csv << #{columns_to_csv(definition, :body, :record=>record)}\n"
              code += "      end\n"
              code += "    end\n"
              code += "    send_data(data, :type=>Mime::CSV, :disposition=>'inline', :filename=>'#{::I18n.translate('activerecord.models.'+model.name.underscore.to_s).gsub(/[^a-z0-9]/i,'_')}.csv')\n"
            end
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

            header = 'content_tag(:tr, ('+header+'), :class=>"header")'

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
            code += "      body += content_tag(:tr, ("+body+"), :class=>'data '+cycle('odd','even', :name=>'dyta')"+opt_line_class+opt_line_style+")\n"
            if children
              code += "      for #{child} in #{record}.#{children}\n"
              code += "        body += content_tag(:tr, ("+child_body+"), :class=>'data child '+cycle('odd','even', :name=>'dyta')"+opt_line_class+opt_line_style+")\n"
              code += "      end\n"
            end
            code += "    end\n"
            code += footer.gsub(/^/, '    ')
            code += "    text = content_tag(:thead, header)+content_tag(:tfoot, #{footer_var})+content_tag(:tbody, body)\n"
            code += "  else\n"
            if options[:empty]
              code += "    text = ''\n"
            else
              code += "    text = '"+content_tag(:tr,content_tag(:td, ::I18n.translate('dyta.no_records').gsub(/\'/,'&apos;'), :class=>:empty))+"'\n"
            end
            code += "  end\n"
            code += footer;
            # code += "  text = content_tag(:table, text, :class=>:dyta, :id=>'"+name.to_s+"') unless request.xhr?\n"
            code += "  text = content_tag(:table, text, :class=>:dyta)\n"
            code += "  text = content_tag(:div, text, :class=>:dyta, :id=>'"+name.to_s+"') unless request.xhr?\n"
            code += "  return text\n"
            code += "end\n"

            # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}

            ActionView::Base.send :class_eval, code

          end

          def value_image(value)
            value = :unknown if value.blank?
            if value.is_a? Symbol
              "image_tag('buttons/"+value.to_s+".png', :border=>0, :alt=>t('"+value.to_s+"'))"
            elsif value.is_a? String
              image = "image_tag('buttons/'+"+value.to_s+"+'.png', :border=>0, :alt=>t("+value.to_s+"))"
              "("+value+".nil? ? '' : "+image+")"
            else
              ''
            end
          end

          def value_image2(value=nil, dir='buttons')
            "image_tag('"+dir.to_s+"/'+("+value.to_s+"||:false).to_s+'.png', :border=>0, :alt=>t(("+value.to_s+"||:false).to_s))"
          end
          
          
          def columns_to_td(definition, nature, options={})
            columns = definition.columns
            code = ''
            record = options[:record]||'RECORD'
            list_method_name = options[:method]||'dyta_list'
            for column in columns
              column_sort = ''
              if column.sortable?
                column_sort = "+(sort=='"+column.name.to_s+"' ? ' sorted' : '')"
              end
              if nature==:header
                code += "+\n      " unless code.blank?
                header_title = "'"+h(column.header).gsub('\'','\\\\\'')+"'"
                if column.sortable?
                  header_title = "link_to_remote("+header_title+", {:update=>'"+options[:id].to_s+"', :loading=>'onLoading();', :loaded=>'onLoaded();', :url=>{:action=>:#{list_method_name}, '#{options[:id]}_sort'=>'"+column.name.to_s+"', '#{options[:id]}_dir'=>(sort=='"+column.name.to_s+"' and dir=='asc' ? 'desc' : 'asc'), :page=>page}}, {:class=>'sort '+(sort=='"+column.name.to_s+"' ? dir : 'unsorted')})"
                end
                code += "content_tag(:th, "+header_title+", :class=>'"+(column.action? ? 'act' : 'col')+"'"+column_sort+")"
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
                      datum = value_image2(datum)
                      style += 'text-align:center;'
                    end
                    if [:date, :datetime, :timestamp].include? column.datatype
                      datum = "(#{datum}.nil? ? '' : ::I18n.localize(#{datum}))"
                    end
                    if column.datatype == :decimal
                      datum = "(#{datum}.nil? ? '' : number_to_currency(#{datum}, :separator=>',', :delimiter=>'&nbsp;', :unit=>'', :precision=>#{column.options[:precision]||2}))"
                    end
                    if column.options[:url] and nature==:body
                    datum = "("+datum+".blank? ? '' : link_to("+datum+', url_for('+column.options[:url].inspect+'.merge({:id=>'+column.record(record)+'.id}))))'
                      css_class += ' url'
                    elsif column.options[:mode] == :download# and !datum.nil?
                      datum = "("+datum+".blank? ? '' : link_to("+value_image(:download)+", url_for_file_column("+record+",'#{column.name}')))"
                      style += 'text-align:center;'
                      # css_class += ' act'
                    elsif column.options[:mode]||column.name == :email
                      # datum = 'link_to('+datum+', "mailto:#{'+datum+'}")'
                      datum = "("+datum+".blank? ? '' : link_to("+datum+", \"mailto:\#\{"+datum+"\}\"))"
                      css_class += ' web'
                    elsif column.options[:mode]||column.name == :website
                      datum = "("+datum+".blank? ? '' : link_to("+datum+", "+datum+"))"
                      css_class += ' web'
                    elsif column.name==:color
                      css_class += ' color'
                      style += "background: #'+"+column.data(record)+"+'; color:#'+viewable("+column.data(record)+")+';"
                    elsif column.name==:country and  column.datatype == :string and column.limit <= 8
                      datum = "(#{datum}.nil? ? '' : '<nobr>'+#{value_image2(datum,'countries')}+'&nbsp;'+::I18n.translate('countries.'+#{datum}))+'</nobr>'"
                    elsif column.datatype == :string
                      datum = "h("+datum+")"
                    end
                    if column.name==:code
                      css_class += ' code'
                    end
                  else
                    datum = 'nil'
                  end
                  code += "content_tag(:td, "+datum+", :class=>'"+column.datatype.to_s+css_class+"'"+column_sort
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
                  code += "content_tag(:td, '&nbsp;&empty;&nbsp;')"
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
                  array << column.header.inspect
                else
                  datum = column.data(record)
                  if column.datatype == :boolean
                    datum = "(#{datum} ? ::I18n.translate('general.dyta_true') : ::I18n.translate('general.dyta_false'))"
                  end
                  if column.datatype == :date
                    datum = "::I18n.localize(#{datum})"
                  end
                  if column.datatype == :decimal
                    datum = "(#{datum}.nil? ? '' : number_to_currency(#{datum}, :separator=>',', :delimiter=>'&nbsp;', :unit=>'', :precision=>#{column.options[:precision]||2}))"
                  end
                  if column.name==:country and  column.datatype == :string and column.limit == 2
                    datum = "(#{datum}.nil? ? '' : ::I18n.translate('countries.'+#{datum}))"
                  end
                  array << datum
                end
              end
            end
            '['+array.join(', ')+']'
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

        def header
          if @options[:label].blank?
            case @nature
            when :column
              if @options[:through] and @options[:through].is_a?(Symbol)
                reflection = @model.reflections[@options[:through]]
                raise Exception.new("Unknown reflection :#{@options[:through].to_s} for the ActiveRecord: "+@model.to_s) if reflection.nil?
                # # @model.columns_hash[@model.reflections[@options[:through]].primary_key_name].human_name
                if reflection.macro == :has_one
                  ::I18n.t("activerecord.attributes.#{reflection.class_name.underscore}.#{@name}")
                else
                  ::I18n.t("activerecord.attributes.#{@model.to_s.tableize.singularize}.#{@model.reflections[@options[:through]].primary_key_name.to_s}")
                end
              elsif @options[:through] and @options[:through].is_a?(Array)
                model = @model
                (@options[:through].size-1).times do |x|
                  model = model.reflections[@options[:through][x]].options[:class_name].constantize
                end
                reflection = @options[:through][@options[:through].size-1].to_sym
                model.columns_hash[model.reflections[reflection].primary_key_name].human_name
              else
                @model.human_attribute_name(@name.to_s)
              end;
            when :action
              'ƒ'
            when :check, :textbox then
              @model.human_attribute_name(@name.to_s)
            else 
              '-'
            end
          else
            @options[:label].to_s
          end
        end
        
        def limit
          @column.limit if @column
        end

        def datatype
          @options[:datatype]||begin
                                 case @column.sql_type
                                 when /int/i
                                   :integer
                                 when /float|double/i
                                   :float
                                 when /^(numeric|decimal|number)\((\d+)\)/i
                                   :integer
                                 when /^(numeric|decimal|number)\((\d+)(,(\d+))\)/i
                                   :decimal
                                 when /datetime/i
                                   :datetime
                                 when /timestamp/i
                                   :timestamp
                                 when /time/i
                                   :time
                                 when /date/i
                                   :date
                                 when /clob/i, /text/i
                                   :text
                                 when /blob/i, /binary/i
                                   :binary
                                 when /char/i, /string/i
                                   :string
                                 when /boolean/i
                                   :boolean
                                 end
                               rescue
                                 nil
                               end
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
          link_options = {}
          link_options[:confirm] = ::I18n.translate('general.'+@options[:confirm].to_s) unless @options[:confirm].nil?
          link_options[:method]  = @options[:method]     unless @options[:method].nil?
          link_options = link_options.inspect.to_s
          link_options = link_options[1..-2]
          verb = @name.to_s.split('_')[-1]
          image_title = @options[:title]||@name.to_s.humanize
          image_file = "buttons/"+(@options[:image]||verb).to_s+".png"
          image_file = "buttons/unknown.png" unless File.file? "#{RAILS_ROOT}/public/images/"+image_file
          format = @options[:format] ? ", :format=>'#{@options[:format]}'" : ""
          if @options[:remote] 
            remote_options = @options.dup
            remote_options[:confirm] = ::I18n.translate('general.'+@options[:confirm].to_s) unless @options[:confirm].nil?
            remote_options.delete :remote
            remote_options.delete :image
            remote_options = remote_options.inspect.to_s
            remote_options = remote_options[1..-2]
            code  = "link_to_remote(image_tag('"+image_file+"', :border=>0, :alt=>'"+image_title+"')"
            code += ", {:url=>{:action=>:"+@name.to_s+", :id=>"+record+".id"+format+"}"
            code += ", "+remote_options+"}"
            code += ", {:alt=>::I18n.t('general.#{verb}'), :title=>::I18n.t('general.#{verb}')}"
            code += ")"
          elsif @options[:actions]
            raise Exception.new("options[:actions] have to be a Hash.") unless @options[:actions].is_a? Hash
            cases = []
            for a in @options[:actions]
              v = a[1][:action].to_s.split('_')[-1]
              cases << record+"."+@name.to_s+".to_s=="+a[0].inspect+"\nlink_to(image_tag('buttons/"+v+".png', :border=>0, :alt=>'"+a[0].to_s+"')"+
                ", {"+(a[1][:controller] ? ':controller=>:'+a[1][:controller].to_s+', ' : '')+":action=>'"+a[1][:action].to_s+"', :id=>"+record+".id"+format+"}"+
                ", {:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+(link_options.blank? ? '' : ", "+link_options)+", :alt=>::I18n.t('general.#{v}'), :title=>::I18n.t('general.#{v}')}"+
                ")\n"
            end

            code = "if "+cases.join("elsif ")+"end"
          else
            url = @options[:url] ||= {}
            url[:controller] ||= @options[:controller]
            url[:action] ||= @name
            url.delete(:id)
            url.delete_if{|k, v| v.nil?}
            code  = "link_to(image_tag('"+image_file+"', :border=>0, :alt=>'"+image_title+"')"
            #code += ", {"+(@options[:controller] ? ':controller=>:'+@options[:controller].to_s+', ' : '')+":action=>:"+@name.to_s+", :id=>"+record+".id"+format+"}"
            code += ", "+url.inspect[0..-2]+", :id=>"+record+".id"+format+"}"
            #+"}"+{"+(@options[:controller] ? ':controller=>:'+@options[:controller].to_s+', ' : '')+":action=>:"+@name.to_s
            code += ", {:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+(link_options.blank? ? '' : ", "+link_options)+", :alt=>::I18n.t('general.#{verb}'), :title=>::I18n.t('general.#{verb}')}"
            code += ")"
          end
          code = "if ("+@options[:if].gsub('RECORD', record)+")\n"+code+"\n end" if @options[:if]
          code
        end
        


      end


      module View
        def dyta(name)
          self.send(name.to_s+'_dyta_tag')
        end
      end

    end

  end
end



if Ekylibre::Dyke::Dyta.will_paginate
  module ActionController
    class RemoteLinkRenderer < WillPaginate::LinkRenderer
      def prepare(collection, options, template)
        @remote = options.delete(:remote) || {}
        super
      end  
      protected
      def page_link(page, text, attributes = {})
        @template.link_to_remote(text, {:url => url_for(page), :method => :get}.merge(@remote), attributes)
      end
    end  
  end
end
