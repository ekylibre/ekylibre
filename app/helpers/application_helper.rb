# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper


  def can_access?(action=:all)
    return false unless @current_user
    return session[:actions].include?(:all) ? true : session[:actions].include?(action)
  end
  
  def elink(condition,label,url)
    link_to_if(condition,label,url) do |name| 
      content_tag :strong, name
    end
  end

  def evalue(object, attribute)
    code  = content_tag :div, object.class.human_attribute_name(attribute.to_s), :class=>:label
    value = object.send(attribute.to_s)
    code += content_tag(:div, value.to_s, :class=>:value)
    content_tag(:div, content_tag(:div,code), :class=>:evalue)
  end

  def menu_modules
    modules = [:index, :accountancy]#, :sales, :purchases, :stocks]
    code = ''
    a = []
    a << action_name.to_sym 
    a << self.controller.controller_name.to_sym
    for m in modules
      if a.include? m
        code += content_tag :strong, l(:guide,m,:title)
      else
        code += link_to(l(:guide,m,:title), {:controller=>:guide, :action=>m})
      end
      code += ' '
    end
    code
  end


  def top_tag
    code = ''
    # Guide Tag
    modules = [:index, :accountancy, :sales, :purchases, :stocks]
    tag = ''    
#    a = [action_name.to_sym, self.controller.controller_name.to_sym]
    for m in modules
#      if a.include? m
#        tag += content_tag :strong, l(:guide,m,:title)
#      else
        tag += link_to(l(:guide,m,:title), {:controller=>:guide, :action=>m})
#      end
      tag += ' '
    end
    code += content_tag(:div, tag, :id=>:guide, :class=>:hm)

    # Fix
    code += content_tag(:div, '', :style=>'left:0pt;')

    # User Tag
    tag = ''
    tag += link_to(@current_user.label, {:controller=>:config, :action=>:user})
    tag += ' '+link_to(@current_company.name, {:controller=>:config, :action=>:company})
    tag += ' '+link_to(lc(:exit), {:controller=>:authentication, :action=>:logout})
    code += content_tag(:div, tag, :id=>:user, :class=>:hm)

    # Fix
    code += content_tag(:div, '', :style=>'clear:both;')
    
    return content_tag(:div, code, :id=>:top)
  end
  

  def css_menu_list(items)
    code = ''
    for item in items
      tag   = link_to(item.name , item.url) +  css_sub_menu(item)
      code += content_tag(:li , tag )
    end
    content_tag(:ul ,code)
  end
  
  def css_sub_menu(item)
    sub_menu = MenuItem.find(:all , :conditions=> { :parent_id => item.parent_id } )
    css_menu_list(sub_menu)
  end
  
  def css_menu_tag(menu , options={})
    menu = Menu.find_by_id(menu) if menu_is_a? Integer
    raise Exception.new("Wrong type") unless menu_is_a? Menu
    menu_items = MenuItem.find(:all , :conditions=> { :parent_id => nil } )
    code = css_menu_list(menu_items)
    code = content_tag(:div,code , {:class=>:menu}.merge(options)) 
    code
  end
  


  def title_tag
    content_tag(:title, 'Ekylibre &bull; '+l(controller.controller_name.to_sym, :title))
  end

  def help_tag
    options = {:class=>"help-link"} 
    url = {:controller=>:help, :action=>:search, :id=>controller.controller_name+'-'+action_name}
    content = content_tag(:div, '&nbsp;')
    options[:style] = "display:none" if session[:help]
    code  = content_tag(:div, link_to_remote(content, :update=>:help,  :url=>url, :complete=>"openHelp();"), {:id=>"help-open"}.merge(options))
  end


  def location_tag(location, options={})
    location = Location.find_by_name(location.to_s) unless location.is_a? Location
    return '' if location.nil?
    content = ''
    content += location.render(@current_user)
    content_tag(:div, content, options.merge({:id=>location.name.to_s, :class=>:location, :align=>"center"}))
  end

  def flash_tag(mode)
    content_tag(:div, flash[mode], :class=>'flash-'+mode.to_s) if flash[mode]
  end

  def link_to_submit(form_name, label=:submit, options={})
    link_to_function(l(label), "document."+form_name+".submit()", options.merge({:class=>:button}))
  end

  def formalize(options={})
    form_name = 'f'+Time.now.to_i.to_s(36)+rand.to_s[2..10]
    form_code = '[No Form Description]'
    if block_given?
      form = FormDefinition.new()
      yield form
      form_code = formalize_lines(form, options)
    elsif options[:model] or options[:partial]
      form_code = render_partial(options[:partial]||options[:model].to_s.tableize+'_form')
    end
    if options[:inner_form]
      code = form_code
    else
      title = ''
      title = content_tag(:h1, l(@controller.controller_name, @controller.action_name,options[:title]), :class=>"title") unless options[:title].nil?
      code  = form_tag({},{:multipart=>options[:multipart]||false, :name=>form_name})
      code += content_tag(:div, form_code, :class=>'fields')
      code += content_tag(:div,submit_tag(l(options[:submit]||:submit))+link_to(l(options[:cancel]||:cancel),:back,:class=>:button),:class=>'actions')
      code += '</form>'
      code = title+content_tag(:div,code)
      html_options = {:class=>'formalize'}
      #      html_options[:style] = "width:"+770.to_s+"px"
      code = content_tag(:div,code, html_options)
    end
    return code
  end

  def formalize_lines(form, form_options)
    code = ''
    controller = self.controller
    # compute column number
    xcn = 3
    column_number = 0
    for line in form.lines
      if line[:nature]==:field
        col = (line[:params].size.to_f/xcn).ceil
      else
        col = 1
      end
      column_number = col if col>column_number
    end
    column_number *= xcn

    help_tags = [:info, :example, :hint]

    # build HTML
    for line in form.lines
      css_class = line[:nature].to_s
      
      # before line      
      code += content_tag(:tr, content_tag(:th,'', :colspan=>column_number), :class=>"before-title") if line[:nature]==:title
      
      # line
      line_code = ''
      case line[:nature]
      when :error
        line_code += content_tag(:td,error_messages_for(line[:params]),:class=>"error", :colspan=>column_number)
      when :title
        reset_cycle "parity"
        line[:value] = l(controller.controller_name, controller.action_name,line[:value]) if line[:value].is_a? Symbol
        line_code += content_tag(:th,line[:value].to_s, :class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>column_number)
      when :field
        css_class += ' '+cycle('odd', 'even', :name=>"parity") 
        col = (line[:params].size.to_f/xcn).ceil
        col.times do |c|
          object_name = line[:params][c*xcn]
          method      = line[:params][c*xcn+1]
          options     = line[:params][c*xcn+2]||{}
          
          object_name.to_sym if object_name.is_a?(String)
          object = object_name.is_a?(Symbol) ? instance_variable_get('@'+object_name.to_s) : object_name
          raise Exception.new('NilError on object: '+object.inspect) if object.nil?
          model = object.class
          raise Exception.new('ModelError on object (not an ActiveRecord): '+object.class.to_s) unless model.methods.include? "create"
          object_name = model.name.underscore.to_sym
          column = model.columns_hash[method.to_s]

          options[:field] = :password if method.to_s.match /password/

          input_id = object.class.name.tableize.singularize+'_'+method.to_s

          html_options = {}
          html_options[:size] = 24
          html_options[:class] = ''
          if column.nil?
            html_options[:class] += ' notnull' unless options[:null]!=false
            if method.to_s.match /password/
              html_options[:size] = 12
              options[:field] = :password if options[:field].nil?
            end
          else
            html_options[:class] += ' notnull' unless column.null
            unless column.limit.nil?
              html_options[:size] = column.limit if column.limit<html_options[:size]
              html_options[:maxlength] = column.limit
            end
            if column.type==:boolean
              options[:field] = :checkbox
            end
          end
          input = case options[:field]
                  when :password
                    password_field object_name, method, html_options
                  when :checkbox
                    check_box object_name, method, html_options
                  else
                    text_field object_name, method, html_options
                  end

          label = if object.class.methods.include? "human_attribute_name"
                    object.class.human_attribute_name(method.to_s)
                  elsif object_name.is_a? Symbol
                    le(:models, object_name.to_sym, :attributes, method.to_sym)
                  else
                    l(controller.controller_name, controller.action_name, object_name)                      
                  end          
          label = content_tag(:label, label, :for=>input_id) if object!=object_name

          help = ''
          for hs in help_tags
            options[hs] = translate_help(options, hs, input_id)
            help += content_tag(:div,l(hs, [content_tag(:span,options[hs].to_s)]), :class=>hs) if options[hs]
          end          
          help_options = {:class=>"help", :id=>options[:help_id]}
          help_options[:colspan] = 1+column_number-xcn*col if c==col-1 and xcn*col<column_number

          label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
          input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
          help  = content_tag(:td, help,  help_options)

          line_code += label+input+help
        end
        (column_number-xcn*col).times{ line_code += content_tag(:td) }
      end
      code += content_tag(:tr, line_code, :class=>css_class) unless line_code.blank?
      
      # after line
      code += content_tag(:tr, content_tag(:th,'', :colspan=>column_number), :class=>"after-title") if line[:nature]==:title
      
    end
    code = content_tag(:table, code, :class=>'formalize')
    # code += 'error_messages_for ' ?
  end
  

#   def formalize_lines2(form, form_options)
#     code = ''
#     controller = self.controller
#     # compute column number
#     column_number = 0
#     for line in form.lines
#       if line[:nature]==:line
#         col = (line[:params].size.to_f/3).ceil
#       else
#         col = 1
#       end
#       column_number = col if col>column_number
#     end
#     column_number *= 3

#     # build HTML
#     for line in form.lines
#       css_class = line[:nature].to_s
      
#       # before line      
#       code += content_tag(:tr, content_tag(:th,'', :colspan=>column_number), :class=>"before-title") if line[:nature]==:title
      
#       # line
#       line_code = ''
#       case line[:nature]
#       when :error
#         line_code += content_tag(:td,error_messages_for(line[:params]),:class=>"error", :colspan=>column_number)
#       when :title
#         reset_cycle "parity"
#         line[:value] = l(controller.controller_name, controller.action_name,line[:value]) if line[:value].is_a? Symbol
#         line_code += content_tag(:th,line[:value].to_s,:class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>column_number)
#       when :line
#         css_class += ' '+cycle('odd','even', :name=>"parity")
#         col = (line[:params].size.to_f/3).ceil
#         col.times do |c|
#           attribute = line[:params][c*3]
#           field     = line[:params][c*3+1]
#           options   = line[:params][c*3+2]||{}
#           options[:controller]=controller
#           field = form_options[:model] if field.blank?
#           if field.is_a? Symbol
#             model  = field.to_s.classify.constantize
#             label  = model.human_attribute_name attribute.to_s
#             column = model.columns_hash[attribute.to_s]
#             input  = ''
#             html_options = {}
#             html_options[:size] = 24
#             html_options[:class] = ''
#             if column.nil?
#               html_options[:class] += ' notnull' unless options[:null]!=false
#               if attribute.to_s.match /password/
#                 html_options[:size] = 12
#                 options[:field] = :password if options[:field].nil?
#               end
#             else
#               html_options[:class] += ' notnull' unless column.null
#               unless column.limit.nil?
#                 html_options[:size] = column.limit if column.limit<html_options[:size]
#                 html_options[:maxlength] = column.limit
#               end
#               if column.type==:boolean
#                 options[:field] = :checkbox
#               end
#             end
#             case options[:field]
#             when :password
#               input = password_field field, attribute, html_options
#             when :checkbox
#               input = check_box field, attribute, html_options
#             else
#               input = text_field field, attribute, html_options
#             end
#             input_id = field.to_s+'_'+attribute.to_s
#           elsif field.is_a? String
#             label = l(controller.controller_name, controller.action_name, attribute)
#             input = field
#             input_id = label
#           else
#             raise Exception.new("Unknown field type: "+field.class.to_s)
#           end
#           options[:example] = [options[:example]] if options[:example].is_a? String
#           help  = ''
          
#           options[:info]    = translate_help(options, :info, input_id)
#           options[:example] = translate_help(options, :example, input_id)
#           options[:hint]    = translate_help(options, :hint, input_id)
          
#           help += content_tag(:div,l(:info, [content_tag(:span,options[:info].to_s)]), :class=>:info) if options[:info]          
#           help += content_tag(:div,l(:example, [content_tag(:span,options[:example])]), :class=>:example) if options[:example]
#           help += content_tag(:div,l(:hint,[content_tag(:span,options[:hint].to_s)]), :class=>:hint) if options[:hint]
          
#           label = content_tag(:label,label, :for=>input_id) if field.is_a? Symbol
#           label = content_tag(:acronym,label, :title=>options[:info]) if options[:info]

#           help_options = {:class=>"help", :id=>options[:help_id]}
#           help_options[:colspan] = 1+column_number-3*col if c==col-1 and 3*col<column_number

#           label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
#           input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
#           help  = content_tag(:td, help,  help_options)
#           line_code += label+input+help
#           # line_code += '<strong>'+field.to_s+'</strong>'
#         end
#         (column_number-3*col).times{ line_code += content_tag(:td) }
#       end
#       code += content_tag(:tr, line_code, :class=>css_class) unless line_code.blank?
      
#       # after line
#       code += content_tag(:tr, content_tag(:th,'', :colspan=>column_number), :class=>"after-title") if line[:nature]==:title
      
#     end
#     code = content_tag(:table, code, :class=>'formalize')
#     # code += 'error_messages_for ' ?
#   end
  







  def translate_help(options,nature,id)
    t = nil
    if options[nature].nil? and id
      t = lh(controller.controller_name.to_sym, controller.action_name.to_sym, (id+'_'+nature.to_s).to_sym)
    elsif options[nature].is_a? Symbol
      t = lc(options[nature])
    elsif options[nature].is_a? String
      t = options[nature]
    end
    return t
  end
  
  
  
  class FormDefinition
    attr_reader :lines

    def initialize()
      @lines = []
    end

    def title(value, options={})
      @lines << options.merge({:nature=>:title, :value=>value})
    end

    def field(*params)
      @lines << {:nature=>:field, :params=>params}
    end

    def error(*params)
      @lines << {:nature=>:error, :params=>params}
    end
  end


end



module SetColumnActiveRecord #:nodoc:
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  module ClassMethods

    def set_column(column, reference)
      code = ''
      col = column.to_s
      reflist = "#{col}_keys".upcase
      if reference.is_a? Hash
#        code += "#{reflist} = {"+reference.collect{|x| ":"+x[0].to_s+"=>\""+x[1].to_s+"\""}.join(",")+"}\n"
        code += "#{reflist} = ["+reference.collect{|x| ":"+x[0].to_s}.join(",")+"]\n"
      elsif reference.is_a? Array
#        code += "#{reflist} = {"+reference.collect{|x| ":"+x.to_s+"=>nil"}.join(",")+"}\n"
        code += "#{reflist} = ["+reference.collect{|x| ":"+x.to_s}.join(",")+"]\n"
      else
        reflist = reference.to_s
      end
      code << <<-"end_eval"
        def #{col}_include?(key)
          key = key.to_sym unless key.is_a?(Symbol)
          return false unless #{reflist}.include?(key)
#          return !self.#{col}.to_s.match("(\ |^)"+key.to_s+"(\ |$)").nil?
          return #{col}_array.include?(key)
        end
        def #{col}_set(key,add=true)
          raise(Exception.new("Only Symbol are accepted")) unless key.is_a?(Symbol)
          return self.#{col} unless #{reflist}.include?(key)
          self.#{col}_array = (add ? self.#{col}_array << key : self.#{col}_array - [key])
          return self.#{col}
        end
        def #{col}_array
          self.#{col}.to_s.split(" ").collect{|key| key.to_sym if #{reflist}.include?(key.to_sym)}.compact
        end
        def #{col}_array=(array)
          self.#{col} = " "+array.flatten.uniq.collect{|key| key.to_sym if #{reflist}.include?(key.to_sym)}.compact.join(" ")+" "
        end
      end_eval
#      ActionController::Base.logger.error(code)
      module_eval(code)
    end
    
  end
end

ActiveRecord::Base.send(:include, SetColumnActiveRecord)

