# Dyta
module Ekylibre
  module Dyke
    module Dyta

      module Controller


        def self.included(base) #:nodoc:
          base.extend(ClassMethods)
        end


        module ClassMethods
          
          include ERB::Util
          include ActionView::Helpers::TagHelper
          include ActionView::Helpers::UrlHelper

          PAGINATION = {
            :will_paginate=>{
              :find_method=>'paginate',
              :find_params=>':page=>params[:page], :per_page=>25'
            },
            :default=>{
              :find_method=>'find',
              :find_params=>''
            }
          }
              

          # Add methods to display a dynamic table
          def dyta(name, options={}, &block)
            options = {:pagination=>:will_paginate}.merge options
            model = (options[:model]||name).to_s.classify.constantize
            begin
              model.columns_hash["id"]
            rescue
              return
            end
            definition = Dyta.new(name, model, options)
            yield definition

            name = name.to_s
            code = ""

            tag_method_name = 'dyta_'+name+'_tag'
            
            # List method
            conditions = ''
            if options[:conditions]
              conditions = ''
              case options[:conditions]
              when Array
                case options[:conditions][0]
                when String  # SQL
                  conditions += '["'+options[:conditions][0].to_s+'"'
                  if options[:conditions].size>1
                    for x in 1..options[:conditions].size-1
                      conditions += ','+sanitize_conditions(options[:conditions][x])
                    end
                  end
                  conditions += ']'
                when Symbol # Method
                  conditions += options[:conditions][0].to_s+'('
                  if options[:conditions].size>1
                    options[:conditions][1..-1].collect{|p| sanitize_conditions(p)}.join(', ')
                  end                  
                  conditions += ')'
                else
                  raise Exception.new("First element of an Array can only be String or Symbol.")
                end
              when Hash # SQL
                conditions += '{'+options[:conditions].collect{|key, value| ':'+key.to_s+'=>'+sanitize_conditions(value)}.join(',')+'}'
              when Symbol # Method
                conditions += options[:conditions].to_s+"(options)"
              when String
                conditions += options[:conditions]
              else
                raise Exception.new("Unsupported type for :conditions: #{options[:conditions].inspect}")
              end
            end

            # code += "hide_action :"+name.to_s+"_list\n"
            code += "def "+name.to_s+"_list(options={})\n"
            code += "  options = (params||{}).merge options\n"
            code += "  order = nil\n"
            code += "  unless options['sort'].blank?\n"
            code += "    options[:dir] ||= 'asc'\n"
            code += "    order  = options['sort']\n"
            code += "    order += options['dir']=='desc' ? ' DESC' : ' ASC'\n"
            code += "  end\n"
   
            code += "  @"+name.to_s+"="+model.to_s+"."+PAGINATION[options[:pagination]][:find_method]+"(:all"
            code += ", :conditions=>"+conditions unless conditions.blank?
#             unless conditions.blank?
#               code += ", :conditions=>"
#               if conditions.is_a? Symbol
#                 code += conditions.to_s+"(options)"
#               else
#                 code += conditions
#               end
#             end
            code += ", "+PAGINATION[options[:pagination]][:find_params] if PAGINATION[options[:pagination]][:find_params]
            code += ", :joins=>#{options[:joins].inspect}" unless options[:joins].blank?
            code += ", :order=>order)\n"
            code += "  if request.xhr?\n"
            code += "    render :inline=>'="+tag_method_name+"('+options.inspect+')', :type=>:haml\n"
            #code += "    render :text=>"+tag_method_name+"(options)\n"
            code += "  end\n"
            code += "end\n"

 #           puts code

            module_eval(code)

            # Tag method
            if definition.procedures.size>0
              process = ''
              for procedure in definition.procedures
                process += "+' '+" unless process.blank?
                process += "link_to(t(\"controllers.\#\{self.controller.controller_name.to_s\}.#{name.to_s}.#{procedure.name.to_s}\"), #{procedure.options.inspect}, :class=>'procedure "+(procedure.options[:action].to_s||'no').split('_')[-1].to_s+"')"
                # process += "link_to(tc(:"+procedure.name.to_s+").gsub(/\ /,'&nbsp;'), "+procedure.options.inspect+", :class=>'procedure "+(procedure.options[:action].to_s||'no').split('_')[-1].to_s+"')"
              end      
              process = "'"+content_tag(:tr, content_tag(:td, "'+"+process+"+'", :class=>:procedures, :colspan=>definition.columns.size))+"'"
            end

            paginate_var = 'pages'
            paginate = case options[:pagination]
                       when :will_paginate then 
                         '  '+paginate_var+"=will_paginate(@"+name.to_s+", :renderer=>'RemoteLinkRenderer', :remote=>{:update=>'"+name.to_s+"'}, :params=>{:sort=>params['sort'], :dir=>params['dir']} )\n  "+
                           paginate_var+"='"+content_tag(:tr, content_tag(:td, "'+"+paginate_var+"+'", :class=>:paginate, :colspan=>definition.columns.size))+"' unless "+paginate_var+".nil?\n"
                       else
                         ''
                       end

            record = 'r'
            header = ''
            body = ''
            sorter  = "    sort = options['sort']\n"
            sorter += "    dir = options['dir']\n"

            for column in definition.columns
              header += "+\n      " unless header.blank?
              header_title = "'"+h(column.header).gsub('\'','\\\\\'')+"'"
              column_sort = ''
#              header_title = "content_tag(:div, '"+h(column.header).gsub('\'','\\\\\'')+"')"
              unless column.action? or column.options[:through]
                # sorter += "    dir_"+column.name.to_s+"=(sort=='"+column.name.to_s+"' and dir=='asc' ? 'desc' : 'asc')\n"
                # header += "dir = (sort=='"+column.name.to_s+"' and dir=='asc' ? 'desc' : 'asc')\n"
                header_title = "link_to_remote("+header_title+", {:update=>'"+name.to_s+"', :loading=>'onLoading();', :loaded=>'onLoaded();', :url=>{:action=>:"+name.to_s+"_list, :sort=>'"+column.name.to_s+"', :dir=>(sort=='"+column.name.to_s+"' and dir=='asc' ? 'desc' : 'asc'), :page=>params[:page]}}, {:class=>'sort '+(sort=='"+column.name.to_s+"' ? dir : 'unsorted')})"
                column_sort = "+(sort=='"+column.name.to_s+"' ? ' sorted' : '')"
#                header += "+link_to_remote("+value_image(:up2)+", {:update=>'"+name.to_s+"', :loading=>'onLoading();', :loaded=>'onLoaded();', :url=>{:action=>:"+name.to_s+"_list, :sort=>'"+column.name.to_s+"', :dir=>'asc', :page=>params[:page]}}, {:class=>'sort'})"
#                header += "+link_to_remote("+value_image(:down2) +", {:update=>'"+name.to_s+"', :loading=>'onLoading();', :loaded=>'onLoaded();', :url=>{:action=>:"+name.to_s+"_list, :sort=>'"+column.name.to_s+"', :dir=>'desc', :page=>params[:page]}}, {:class=>'sort'})"
              end
              header += "content_tag(:th, "+header_title+", :class=>'"+(column.action? ? 'act' : 'col')+"'"+column_sort+")"
              body   += "+\n        " unless body.blank?
              case column.nature
              when :column
                style = options[:style]||''
                css_class = ''
                datum = column.data(record)
                if column.datatype == :boolean
                  datum = value_image2(datum)
                  style = 'text-align:center;'
                end
                if column.options[:url]              
                  datum = "("+datum+".blank? ? '' : link_to("+datum+', url_for('+column.options[:url].inspect+'.merge({:id=>'+column.record(record)+'.id}))))'
                  css_class += ' url'
                elsif column.options[:mode] == :download# and !datum.nil?
                  datum = 'link_to('+value_image(:download)+', url_for_file_column('+column.data(record)+",'"+column.name+"'))"
                  style = 'text-align:center;'
                  css_class += ' act'
                elsif column.options[:mode]||column.name == :email
                  # datum = 'link_to('+datum+', "mailto:#{'+datum+'}")'
                  datum = "("+datum+".blank? ? '' : link_to("+datum+", \"mailto:\#\{"+datum+"\}\"))"
                  css_class += ' web'
                elsif column.options[:mode]||column.name == :website
                  datum = "("+datum+".blank? ? '' : link_to("+datum+", "+datum+"))"
                  css_class += ' web'
                end
                if column.options[:name]==:color
                  css_class += ' color'
                  style = "background: #'+"+column.data(record)+"+'; color:#'+viewable("+column.data(record)+")+';"
                end
                body += "content_tag(:td, "+datum+", :class=>'"+column.datatype.to_s+css_class+"'"+column_sort
                body += ", :style=>'"+style+"'" unless style.blank?
                body += ")"
              when :action
                body += "content_tag(:td, "+column.operation(record)+", :class=>'act')"
              else 
                body += "content_tag(:td, '&nbsp;&empty;&nbsp;')"
              end
            end

            header = 'content_tag(:tr, ('+header+'), :class=>"header")'

            #code += "hide_action :"+tag_method_name+"\n"
            code  = "def "+tag_method_name+"(options={})\n"
            code += "  @"+name.to_s+"=@"+name.to_s+"||{}\n"
            code += "  if @"+name.to_s+".size>0\n"
            code += sorter
            code += "    header = "+header+"\n"
            code += "    reset_cycle('dyta')\n"
            code += "    body = ''\n"
            code += "    for "+record+" in @"+name.to_s+"\n"
            code += "      body += content_tag(:tr, ("+body+"), :class=>'data '+cycle('odd','even', :name=>'dyta')"+(options[:line_class].blank? ? '' : '+" "+('+options[:line_class].gsub(/RECORD/,record)+')')+")\n"
            code += "    end\n"
            code += "    text = header+content_tag(:tbody,body)\n"
            code += "  else\n"
            if options[:empty]
              code += "    text = ''\n"
            else
              code += "    text = '"+content_tag(:tr,content_tag(:td,tg('no_records').gsub(/\'/,'&apos;'), :class=>:empty))+"'\n"
            end
            code += "  end\n"
            code += paginate;
            code += "  text = "+process+"+text\n" unless process.nil?
            code += "  text += "+paginate_var+".to_s\n"
            code += "  unless request.xhr?\n"
            code += "    text = content_tag(:table, text, :class=>:dyta, :id=>'"+name.to_s+"')\n"
            # code += "  text = content_tag(:div, text)\n"
            code += "    text = content_tag(:h3,  "+h(options[:label])+", :class=>:dyta)+text\n" unless options[:label].nil?
            # code += "  text = content_tag(:div, text, :class=>'futo', )\n"
            # code += "  text = content_tag(:h2,  "+options[:title]+", :class=>'futo')+text\n" unless options[:title].nil?
            code += "  end\n"
            code += "  text\n"
            code += "end\n"

            ActionView::Base.send :class_eval, code

            # Finish
           # puts code
          end

          def value_image(value)
            if value.is_a? Symbol
              "image_tag('buttons/"+value.to_s+".png', :border=>0, :alt=>t('"+value.to_s+"'))"
            elsif value.is_a? String
              image = "image_tag('buttons/'+"+value.to_s+"+'.png', :border=>0, :alt=>t("+value.to_s+"))"
              "("+value+".nil? ? '' : "+image+")"
            else
              ''
            end
          end

          def value_image2(value)
            "image_tag('buttons/'+"+value.to_s+".to_s+'.png', :border=>0, :alt=>t("+value.to_s+".to_s))"
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
            else
              value.to_s
            end
          end

        end  

      end





      # Dyta represents a DYnamic TAble
      class Dyta
        attr_reader :name, :model, :options
        attr_reader :columns, :procedures
        
        def initialize(name, model, options)
          @name    = name
          @model   = model
          @options = options
          @columns = []
          @procedures = []
        end
        
        def column(name, options={})
          @columns << DytaElement.new(model,:column,name,options)
        end
        
        def action(name, options={})
          @columns << DytaElement.new(model,:action,name,options)
        end
        
        def procedure(name, options={})
          options[:action] = name if options[:action].nil?
          @procedures << DytaElement.new(model,:procedure,name,options)
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

        def header
          if @options[:label].blank?
            case @nature
            when :column
              if @options[:through] and @options[:through].is_a?(Symbol)
                raise Exception.new("Unknown reflection :#{@options[:through].to_s} for the ActiveRecord: "+@model.to_s) if @model.reflections[@options[:through]].nil?
                # @model.columns_hash[@model.reflections[@options[:through]].primary_key_name].human_name
                ::I18n.t("activerecord.attributes.#{@model.to_s.tableize.singularize}.#{@model.reflections[@options[:through]].primary_key_name.to_s}")
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
            else 
              '-'
            end
          else
            @options[:label].to_s
          end
        end
        
        def datatype
          begin
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

        def data(record='record')
          code = if @options[:through]
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
          link_options = link_options[1..link_options.size-2]
          image_title = @options[:title]||@name.to_s.humanize
          image_file = "buttons/"+(@options[:image]||@name).to_s+".png"
          image_file = "buttons/unknown.png" unless File.file? "#{RAILS_ROOT}/public/images/"+image_file
          if @options[:remote] 
            remote_options = @options.dup
            remote_options.delete :remote
            remote_options.delete :image
            remote_options = remote_options.inspect.to_s
            remote_options = remote_options[1..-2]
            code  = "link_to_remote(image_tag('"+image_file+"', :border=>0, :alt=>'"+image_title+"')"
            code += ", :url=>{:action=>:"+@name.to_s+", :id=>"+record+".id}"
            code += ", "+remote_options
            code += ")"
          elsif @options[:actions]
            raise Exception.new("options[:actions] have to be a Hash.") unless @options[:actions].is_a? Hash
            cases = []
            for a in @options[:actions]
              cases << record+"."+@name.to_s+".to_s=="+a[0].inspect+"\nlink_to(image_tag('buttons/"+a[1][:action].to_s.split('_')[-1]+".png', :border=>0, :alt=>'"+a[0].to_s+"')"+
                ", {:action=>'"+a[1][:action].to_s+"', :id=>"+record+".id}"+
                ", {:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+(link_options.blank? ? '' : ", "+link_options)+"}"+
                ")\n"
            end

            code = "if "+cases.join("elsif ")+"end"
          else
            code  = "link_to(image_tag('"+image_file+"', :border=>0, :alt=>'"+image_title+"')"
            code += ", {:action=>:"+@name.to_s+", :id=>"+record+".id}"
            code += ", {:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+(link_options.blank? ? '' : ", "+link_options)+"}"
            code += ")"
          end
          code = "if ("+@options[:if].gsub('RECORD', record)+")\n"+code+"\n end" if @options[:if]
          code
        end
        


      end


      module View
        def dyta(name)
#          self.controller.send('dyta_'+name.to_s+'_tag')
          self.send('dyta_'+name.to_s+'_tag')
        end
      end

    end

  end
end

