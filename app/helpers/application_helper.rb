# Methods added to this helper will be available to all templates in the application.
module ActiveRecord
  class Base
    def lc(*args)
      'lc('+args.inspect+')'
    end
  end
end

module ApplicationHelper
  
  MENUS=
    [ 
     # GuideController
     {:name=>:guide, :list=>
       [ {:name=>:modules, :list=>
           [ {:name=>:relations, :url=>{:controller=>:relations}},
             {:name=>:accountancy, :url=>{:controller=>:accountancy}},
             {:name=>:management, :url=>{:controller=>:management}} ] },
         {:name=>:informations, :class=>:special, :list=>
           [ {:name=>:about_us} ] }
       ] },
     # RelationsController
     {:name=>:relations, :list=>
       [ {:name=>:entities_managing, :list=>
           [ {:name=>:entities}
             #  ,{:name=>:entities_create} 
           ] }
       ] },
     # AccountancyController
     {:name=>:accountancy, :list=>
       [ {:name=>:works, :list=>
           [ {:name=>:entries},
             {:name=>:statements},
             {:name=>:lettering},
             {:name=>:journals_close},
             {:name=>:financialyears_close} ] },
         {:name=>:documents, :list=>
           [ {:name=>:document_prepare} ] },
         {:name=>:parameters, :list=>
           [ {:name=>:accounts},
             {:name=>:journals},
             {:name=>:bank_accounts},
             {:name=>:financialyears} ] }
       ] },
     # ManagementController
     {:name=>:management, :list=>
       [ {:name=>:sales, :list=>
           [ {:name=>:sales_new},
             {:name=>:sales_consult, :url=>{:action=>:sales}} ] },
         {:name=>:purchases, :list=>
           [ {:name=>:purchases_new},
             {:name=>:purchases_consult, :url=>{:action=>:purchases}} ] },
         {:name=>:stocks, :list=>
           [ {:name=>:stocks_locations},
             {:name=>:stocks_consult, :url=>{:action=>:stocks}} ] },
         {:name=>:parameters, :list=>
           [ {:name=>:products},
             {:name=>:price_lists},
             {:name=>:shelves} ] }
       ] }
    ]


  MENUS_ARRAY = MENUS.collect{|x| x[:name]}
            

  def lc(*args)
    args.inspect
  end
            
  def menus
    MENUS
  end
  
  def menu_index(controller=self.controller.controller_name.to_sym)
    for m in MENUS
      return render(:partial=>'shared/menu_index', :locals=>{:menu=>m}) if m[:name]==controller
    end
    ''
  end
    

  def can_access?(action=:all)
    return false unless @current_user
    return session[:actions].include?(:all) ? true : session[:actions].include?(action)
  end

  def link_to_back(options={})
    {:url=>:back}.merge(options)
    link_to l('back'), options[:url], :class=>:back
  end

  
  def elink(condition,label,url)
    link_to_if(condition,label,url) do |name| 
      content_tag :strong, name
    end
  end

  def evalue(object, attribute, options={})
    if object.is_a? String
      label = object
      value = attribute.to_s
    else
      label = object.class.human_attribute_name(attribute.to_s)
      value = object.send(attribute.to_s).to_s
    end
    value = link_to(value.to_s, options[:url]) if options[:url]
    code  = content_tag(:div, label.to_s, :class=>:label)
    code += content_tag(:div, value.to_s, :class=>:value)
    content_tag(:div, content_tag(:div,code), :class=>:evalue)
  end


  def left_tag
    return '' if !MENUS_ARRAY.include? self.controller.controller_name.to_sym or action_name=="index"
    content_tag(:div, menu_index, :id=>:side, :flex=>2, :orient=> :vertical)
  end


  def top_tag
    return '' if @current_user.blank?
    code = ''
    # Guide Tag
    tag = ''
    for m in MENUS
      tag += elink(self.controller.controller_name!=m[:name].to_s, t(m[:name], :title),{:controller=>m[:name]})+" "
    end
    tag = content_tag(:nobr, tag);
  #  tag += css_menu_tag(session[:menu_guide])
    code += content_tag(:div, tag, :id=>:guide, :class=>:menu)
    # Fix
    tag = ''
    tag += image_tag('template/ajax-loader-2.gif', :id=>:loading, :style=>'display:none;')
    #    tag  = content_tag :div, tag
    code += content_tag(:div, tag, :style=>'text-align:center;', :align=>:center, :flex=>1)
    #    code += content_tag(:div, tag, :style=>'left:0pt;')
    
    # User Tag
    tag = ''
    tag += link_to(@current_user.label, {:controller=>:company, :action=>:user})+" "
    tag += link_to(@current_company.name, {:controller=>:company})+" "
    tag += link_to(lc(:exit), {:controller=>:authentication, :action=>:logout})+" "
    tag = content_tag(:nobr, tag);
#    tag += css_menu_tag(session[:menu_user]) 
    code += content_tag(:div, tag, :id=>:user, :class=>:menu, :align=>:right)
    
    # Fix
    #    code += content_tag(:div, '', :style=>'clear:both;')    
    code = content_tag(:div, code, :id=>:top, :orient=>:horizontal)
    code
  end

  def menu_item_title(item)
    title = item.name
    if item.dynamic
      title.gsub!('$company_name' , @current_company.name)
      title.gsub!('$user_name' , @current_user.name)
      title.gsub!('$user_label' , @current_user.label)
    end
    title
  end


  def css_menu_list(items)
    code = ''
    name_company =  @current_company.name 
    name_user    =  @current_user.name
    for item in items
      menu_item_title(item)
      if item.dynamic
        if item.name == @current_company.name
          tag   = link_to(name_company , item.url) +  css_sub_menu(item)
        elsif item.name == @current_user.label
          tag   = link_to(name_user , item.url) +  css_sub_menu(item)
        else 
          tag   = link_to('Quitter' , item.url) +  css_sub_menu(item)
        end
      else
        tag   = link_to(item.name , item.url) +  css_sub_menu(item)
      end
      code += content_tag(:li , tag )
    end
    content_tag(:ul ,code)
  end
  
  def css_sub_menu(item)
    sub_menu = MenuItem.find(:all ,:order=>"position ASC",  :conditions=> { :parent_id => item.id } )
    if sub_menu.size == 0 
      return ''
    else
      css_menu_list(sub_menu)
    end 
  end
  
  def css_menu_tag(menu , options={})
    menu = Menu.find_by_id(menu) if menu.is_a? Integer
    raise Exception.new("Wrong type:"+menu.class.to_s) unless menu.is_a? Menu
    menu_items = MenuItem.find(:all ,:order=>"position ASC", :conditions=> { :parent_id => nil , :menu_id => menu} )#. NULL AND menu_id = ?', menu ] )
    code = css_menu_list(menu_items)
    code = content_tag(:div,code , {:class=>:menu}.merge(options)) 
    code
  end
  


  def title_tag
#    content_tag(:title, 'Ekylibre - '+t(controller.controller_name.to_sym, :title))
    content_tag(:title, 'Ekylibre - '+t(controller.controller_name.to_sym))
  end

  def help_tag
    return '' if @current_user.blank?
    options = {:class=>"help-link"} 
    url = {:controller=>:help, :action=>:search, :id=>controller.controller_name+'-'+action_name}
    content = content_tag(:div, '&nbsp;')
    options[:style] = "display:none" if session[:help]
    code  = content_tag(:div, link_to_remote(content, :update=>:help,  :url=>url, :complete=>"openHelp();", :loading=>"onLoading();", :loaded=>"onLoaded();"), {:id=>"help-open"}.merge(options))
  end


  def location_tag(location, options={})
    location = Location.find_by_name(location.to_s) unless location.is_a? Location
    return '' if location.nil?
    content = ''
    content += location.render(@current_user)
    content_tag(:div, content, options.merge({:id=>location.name.to_s, :class=>:location, :align=>"center"}))
  end

  def flash_tag(mode)
#    content_tag(:div, 'Blabla', :class=>'flash '+mode.to_s)
    content_tag(:div, flash[mode], :class=>'flash '+mode.to_s) if flash[mode]
  end

  def link_to_submit(form_name, label=:submit, options={})
    link_to_function(l(label), "document."+form_name+".submit()", options.merge({:class=>:button}))
  end

  def old_formalizess(options={})
    form_name = 'f'+Time.now.to_i.to_s(36)+rand.to_s[2..10]
    form_code = '[No Form Description]'
    if block_given?
      form = FormDefinition.new()
      yield form
      form_code = formalize_lines(form, options)
    elsif options[:model] or options[:partial]
      form_code = render_partial(options[:partial]||options[:model].to_s.tableize+'_form', :locals=>{:formalize_partial=>options[:partial]})
    end
    if options[:inner_form]
      code = form_code
    else
#      title = ''
#      title = content_tag(:h1, l(@controller.controller_name, @controller.action_name,options[:title]), :class=>"title") unless options[:title].nil?
      code  = form_tag(options[:url]||{},{:multipart=>options[:multipart]||false, :name=>form_name})
      code += content_tag(:div, form_code, :class=>'fields')
      code += content_tag(:div,submit_tag(l(options[:submit]||:submit))+link_to(l(options[:cancel]||:cancel),:back,:class=>:button),:class=>'actions')
      code += '</form>'
 #     code = title+content_tag(:div,code)
      code = content_tag(:div, code, :class=>'formalize')
    end
    return code
  end


  def formalize(options={})
    code = '[NoFormDescriptionError]'
    if block_given?
      form = FormDefinition.new()
      yield form
      code = formalize_lines(form, options)
    end
    return code
  end


  # This methods build a form line after line
  def formalize_lines(form, form_options)
    code = ''
    controller = self.controller
    xcn = 2
    
    # build HTML
    for line in form.lines
      css_class = line[:nature].to_s
      
      # before line      
      # code += content_tag(:tr, content_tag(:th,'', :colspan=>xcn), :class=>"before-title") if line[:nature]==:title
      
      # line
      line_code = ''
      case line[:nature]
      when :error
        line_code += content_tag(:td,error_messages_for(line[:params]),:class=>"error", :colspan=>xcn)
      when :title
#        reset_cycle "parity"
        if line[:value].is_a? Symbol
          calls = caller
          file = calls[3].split(':')[0].split('/')[-1].split('.')[0]
          file = file[1..-1] if file[0..0]=='_'
#          line[:value] = l(controller.controller_name, file.to_sym,line[:value]) 
          line[:value] = t(line[:value]) 
        end
        line_code += content_tag(:th,line[:value].to_s, :class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>xcn)
      when :field
#        css_class += ' '+cycle('odd', 'even', :name=>"parity")
        fragments = line_fragments(line)
        line_code += content_tag(:td, fragments[:label], :class=>"label")
        line_code += content_tag(:td, fragments[:input], :class=>"input")
        # line_code += content_tag(:td, fragments[:help],  :class=>"help")
      end
      unless line_code.blank?
        html_options = line[:html_options]||{}
        html_options[:class] = css_class
        code += content_tag(:tr, line_code, html_options)
      end
    
      # after line
      # code += content_tag(:tr, content_tag(:th,'', :colspan=>xcn), :class=>"after-title") if line[:nature]==:title
      
    end
    code = content_tag(:table, code, :class=>'formalize')
    # code += 'error_messages_for ' ?
  end



  def line_fragments(line)
    help_tags = [:info, :example, :hint]
    fragments = {}

    help = ''
    for hs in help_tags
      line[hs] = translate_help(line, hs)
#      help += content_tag(:div,l(hs, [content_tag(:span,line[hs].to_s)]), :class=>hs) if line[hs]
      help += content_tag(:div,t(hs), :class=>hs) if line[hs]
    end
    fragments[:help] = help

    #          help_options = {:class=>"help", :id=>options[:help_id]}
    #          help_options[:colspan] = 1+xcn-xcn*col if c==col-1 and xcn*col<xcn
    #label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
    #input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
    #help  = content_tag(:td, help,  :class=>"help",  :id=>options[:help_id])

    if line[:model] and line[:attribute]
      record = line[:model]
      method      = line[:attribute]
      options     = line

      record.to_sym if record.is_a?(String)
      object = record.is_a?(Symbol) ? instance_variable_get('@'+record.to_s) : record
      raise Exception.new('NilError on object: '+object.inspect) if object.nil?
      model = object.class
      raise Exception.new('ModelError on object (not an ActiveRecord): '+object.class.to_s) unless model.methods.include? "create"

#      record = model.name.underscore.to_sym
      column = model.columns_hash[method.to_s]
      
      options[:field] = :password if method.to_s.match /password/
      
      input_id = object.class.name.tableize.singularize+'_'+method.to_s

      html_options = {}
      html_options[:size] = 24
      html_options[:class] = ''
      if column.nil?
        html_options[:class] += ' notnull' if options[:null]==false
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
        html_options[:size] = 10 if column.type==:date
      end
      
      if options[:choices].is_a? Array
        options[:field] = :select if options[:field]!=:radio
        html_options.delete :size
        html_options.delete :maxlength
      end
      
      input = case options[:field]
              when :password
                password_field record, method, html_options
              when :checkbox
                check_box record, method, html_options
              when :select
                select record, method, options[:choices], options[:options]||{}, html_options
              when :radio
                options[:choices].collect{|x| radio_button(record, method, x[1])+"&nbsp;"+content_tag(:label,x[0],:for=>input_id+'_'+x[1])}.join " "
              when :textarea
                text_area record, method, :cols => 30, :rows => 3
              else
                text_field record, method, html_options
              end
      if options[:field] = :select and options[:new].is_a? Hash
        label = lc(options[:new][:label]||:new)
        options[:new].delete :label
        input += link_to(label, options[:new], :class=>:fastadd)
      end


#      input += content_tag(:h6,options[:field].to_s+' '+options[:choices].class.to_s+' '+options.inspect)
      
      label = if object.class.methods.include? "human_attribute_name"
                object.class.human_attribute_name(method.to_s)
              elsif record.is_a? Symbol
                le(:models, record.to_sym, :attributes, method.to_sym)
              else
                l(controller.controller_name, controller.action_name, record)                      
              end          
      label = content_tag(:label, label, :for=>input_id) if object!=record
    elsif line[:field]
      label = line[:label]||'[NoLabel]'
      input = line[:field]
    else
      raise Exception.new("Unable to build fragments without :model/:attribute or :field")
    end
    fragments[:label] = label
    fragments[:input] = input
    return fragments
  end
  

  def translate_help(options,nature,id=nil)
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
#      @lines << {:nature=>:field, :params=>params}
      line = params[2]||{}
#      line[:help] = 
#      line.merge({:nature=>:field, :help=>params[2]})
      if params[1].is_a? Symbol
        line[:model] = params[0]
        line[:attribute] = params[1]
      else
        line[:label] = params[0]
        line[:field] = params[1]
      end
      line[:nature] = :field
      @lines << line
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


# Hack to clean textilize

module ActionView
  module Helpers #:nodoc:
    # The TextHelper module provides a set of methods for filtering, formatting
    # and transforming strings, which can reduce the amount of inline Ruby code in
    # your views. These helper methods extend ActionView making them callable
    # within your template files.
    module TextHelper
      begin
        require_library_or_gem "redcloth" unless Object.const_defined?(:RedCloth)
        def textilize(text, *rules)
          if text.blank?
            ""
          else
            rc = RedCloth.new(text, rules)
            rc.no_span_caps = true
            rc.to_html
          end
        end
      rescue LoadError
        # We can't really help what's not there
      end
    end
  end
end



