# AjaxTable
module AjaxTable

  def ajax_table (table,options={:label=>nil, :records=>nil, :style=>''}, &block)
    records = options[:records].nil? ? instance_variable_get("@#{table.to_s}") : options[:records]
    record_pages = instance_variable_get("@#{table.to_s.singularize.to_s}_pages") if record_pages.nil?
    model  = table.to_s.singularize.camelize.constantize
    definition = OutputTableDefinition.new(model)
    yield definition
    colnb = definition.columns.size
    # Procedures    
    search = ''
    unless options[:search].nil?
      search  = content_tag('label','Recherche')
      search += content_tag('input','', :type=>"text",:id=>:search_clue, :name=>"search[clue]", :size=>30)
      search += content_tag('input', '', :src=>"/images/buttons/search.png", :type=>"image", :name=>"commit")
      #, :type=>"submit", :value=>"Trouver")
      search  = content_tag('form',search,:action=>"/"+self.controller.controller_path+'/'+options[:search].to_s, :method=>:post)
      search  = content_tag('div',search,:class=>"search")
    end
    process = ''
    if definition.procedures.size>0
      definition.procedures.size.times do |proc|
#      for proc in 0..(definition.procedures.size-1)
#        process += ' &nbsp;&bull;&nbsp; ' if proc>0
        process += ' ' if proc>0
        process += link_to(lc(definition.procedures[proc][0]).gsub(/\ /,"&nbsp;"), definition.procedures[proc][1], :class=>"button")
      end      
      process = content_tag 'tr', content_tag('td',process,:class=>"menu", :colspan=>colnb)
    end
    code = ''
    reset_cycle('fparity')

    if records and records.size>0
      line = ''
      for column in definition.columns
        case column.nature
        when :datum  : line += content_tag('th', h(column.header))
        when :action : line += content_tag('th', column.header, :class=>"act")
        end
      end
      code  = content_tag('tr',line)
      for record in records
        line = ''
        for column in definition.columns
          case column.nature
            when :datum  :
              style = options[:style]
              css_class = ''
              datum = column.data(record)
              if column.datatype==:boolean
                datum = value_image(datum)
                style='text-align:center;'
              end
              datum = link_to datum, url_for(column.url(record)) if column.is_linkable?
              if column.options[:mode]==:download and !datum.nil?
                datum = link_to(value_image('download'), url_for_file_column(record, column.options[:name])) 
                style='text-align:center;'
                css_class = ' act'
              end
              if column.options[:name]==:color
                style='text-align:center; width:6ex; border:1px solid black; background: #'+datum+'; color:#'+viewable(datum)+';'
              end
              line += content_tag('td', datum, :class=>column.datatype.to_s+css_class, :style=>style)
#              case column.datatype
#                when :date    : line += content_tag('td', , :align=>"center")
#                when :decimal : line += content_tag('td', column.data(record), :align=>"right")
#                when :integer : line += content_tag('td', column.data(record), :align=>"right")
#                when :float   : line += content_tag('td', column.data(record), :align=>"right")
#                when :boolean : line += content_tag('td', value_image(column.data(record)), :align=>"center")
#                else line += content_tag('td', h(column.data(record)))
#              end
            when :action : line += content_tag('td', column.valids_condition(record) ? operation(record, column.options) : "" , :class=>"act") 
            else line += content_tag('td','&nbsp;&empty;&nbsp;')
          end
        end
        code += content_tag('tr',line, :class=>'data '+cycle('odd','even', :name=>'fparity'))
      end
    else
      code += content_tag(:tr,content_tag(:td, l(:no_records), :colspan=>definition.columns.size, :class=>"empty"))
    end
    line = ''
    if record_pages
      line += link_to('Previous page', { :page => record_pages.current.previous }) if record_pages.current.previous
      if record_pages.current.next
        line += ' &bull; ' if line.size>0
        line += link_to('Next page', { :page => record_pages.current.next })
      end
    end
    code += content_tag('tr',content_tag('td',line, :colspan=>definition.columns.size, :class=>"navigation")) if line.size>0
    code = process+code
    code = search+content_tag('table', code, :class=>"list")
    code = content_tag('div', code)
    code = content_tag('h3',  h(options[:label])) + code unless options[:label].nil?
    code = content_tag('div', code)
    code = content_tag('div', code, :class=>"futo")
    code = content_tag('h2', options[:title], :class=>"futo") + code unless options[:title].nil?
    code
  end

  # Action columns
  def operation(object, operation, controller_path=self.controller.controller_path)
    return "" if not operation[:condition].nil? and operation[:condition]==false
    code = ""
    operation[:action] = operation[:actions][object.send(operation[:use]).to_s] if operation[:use]
    parameters = {}
    parameters[:confirm] = l(operation[:confirm]) unless operation[:confirm].nil?
    parameters[:method]  = operation[:method]    unless operation[:method].nil?
    parameters[:id]      = operation[:action].to_s+"-"+(object.nil? ? 0 : object.id).to_s
    
    image_title = operation[:title].nil? ? operation[:action].to_s.humanize : operation[:title]
    dir = "#{RAILS_ROOT}/public/images/"
    image_file = "buttons/"+(operation[:image].nil? ? operation[:action].to_s.gsub(operation[:prefix].to_s||"","") : operation[:image].to_s)+".png"
    image_file = "buttons/unknown.png" unless File.file? dir+image_file
    code += link_to image_tag(image_file, :border => 0, :alt=>image_title, :title=>image_title), {:action => operation[:action].to_s, :id => object.id}, parameters
    code
  end

  def value_image(value)
    unless value.nil?
      image = nil
      case value.to_s
        when "true" : image = "true"
        when "false" : image = nil
        else image =  value.to_s
      end
#      "<div align=\"center\">"+image_tag("buttons/"+image+".png", :border => 0, :alt=>image.t, :title=>image.t)+"</div>" unless image.nil?
      image_tag("buttons/"+image+".png", :border => 0, :alt=>l(image), :title=>l(image)) unless image.nil?
    end
  end
  




end  
  












  class OutputTableColumn
     attr_reader :nature, :options
    def initialize(model, nature=:data, options={:name=>nil, :type=>:string})
      @model           = model
      @nature          = nature
      @options         = options
      if @options[:through].is_a? Array
        if @options[:through].size==1
          @options[:through] = @options[:through][0]
        end
      end
    end
    
    def header
      if @options[:label]
        @options[:label].to_s
      else
        case @nature
          when :datum :
            if @options[:through] and @options[:through].is_a?(Symbol)
#              @model.reflections[@options[:through]].class_name.constantize.localized_model_name
              raise Exception.new("Unknown reflection :#{@options[:through].to_s} for the ActiveRecord: "+@model.to_s) if @model.reflections[@options[:through]].nil?
              @model.columns_hash[@model.reflections[@options[:through]].primary_key_name].human_name
            elsif @options[:through] and @options[:through].is_a?(Array)
              model = @model
              for x in 0..@options[:through].size-2
                model = model.reflections[@options[:through][x]].options[:class_name].constantize
              end
              reflection = @options[:through][@options[:through].size-1].to_sym
              model.columns_hash[model.reflections[reflection].primary_key_name].human_name
            else
#              raise Exception.new("Unknown property :#{@options[:name].to_s} for the ActiveRecord: "+@model.to_s) if @model.columns_hash[@options[:name].to_s].nil?
              @model.human_attribute_name(@options[:name].to_sym)
            end;
          when :action : 'ƒ'
          else '-'
        end
      end
    end
    
    def data(record)
      if @options[:through]
        if @options[:through].is_a?(Array)
          r = record
          for x in 0..@options[:through].size-1
            r = r.send(@options[:through][x])
          end
          r.nil? ? nil : r.send(@options[:name])
        else
          r = record.send(@options[:through])
          r.nil? ? nil : r.send(@options[:name])
        end
      else
        record.send(@options[:name])
      end
    end
    
    def is_linkable?
      @options[:url]
    end
    
    def url(record)
      @options[:url][:id]= get_record(record).id unless @options[:id] and @options[:id]==:none
      @options[:url]
    end
    
    def datatype
      @model.columns_hash[@options[:name].to_s].send(:type)
    end
    
    def valids_condition(record)
      condition = @options[:condition]
      if condition
        cond = condition.to_s
        if cond.match /^not__/
          !record.send(cond[5..255])
        else
          record.send(cond)
        end
      else
        true
      end
    end
    
    private
    
    def get_record(record)
      if @options[:through]
        if @options[:through].is_a?(Array)
          r = record
          for x in 0..@options[:through].size-1
            r = r.send(@options[:through][x])
          end
          r
        else
          record.send(@options[:through])
        end
      else
        record
      end
    end
    
  end

  class OutputTableDefinition
    attr_reader :columns, :data_count, :link_count, :model, :procedures

    def initialize(model)
      @model = model
      @columns = []
      @procedures = []
      @data_count = 0
      @link_count = 0
    end

    def datum(name,options={:type=>:string})
      options[:name] = name
      @columns << OutputTableColumn.new(@model, :datum, options)
      @data_count += 1      
    end
    alias :column :datum

    def procedure(name,url={})
      @procedures << [name,url]
    end

    def action(options)
      if options.is_a? Hash
        @columns << OutputTableColumn.new(@model, :action, options)
        @link_count += 1      
      elsif options.is_a? Symbol
        case options
          when :none    :
          when :default :
            @columns << OutputTableColumn.new(@model, :action, {:action=>:show})
            @columns << OutputTableColumn.new(@model, :action, {:action=>:edit})
            @columns << OutputTableColumn.new(@model, :action, {:action=>:destroy, :method=>:post, :confirm=>'Are you sure?'})
            @link_count += 3
          when :show    :
            @columns << OutputTableColumn.new(@model, :action, {:action=>:show})
            @link_count += 1
          when :edit    :
            @columns << OutputTableColumn.new(@model, :action, {:action=>:edit})
            @link_count += 1
          when :destroy :
            @columns << OutputTableColumn.new(@model, :action, {:action=>:destroy, :method=>:post, :confirm=>'Are you sure?'})
            @link_count += 1
          else
            @columns << OutputTableColumn.new(@model, :action, {:action=>:options})
            @link_count += 1
        end
      end
    end

  end
  






