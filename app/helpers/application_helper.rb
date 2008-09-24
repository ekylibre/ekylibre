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
        code += link_to(l(:guide,m,:title), :controller=>:guide, :action=>m)+' '
      end
    end
    code
  end

  def formalize(options={})
    title = ''
    title = content_tag(:h1, l(@controller.controller_name, @controller.action_name,options[:title]), :class=>"title") unless options[:title].nil?
    code  = form_tag({},:multipart=>options[:multipart]||false)
    form_code = '[No Form Description]'
    if block_given?
      form = FormDefinition.new()
      yield form
      form_code = formalize_lines(form)
    elsif options[:model] or options[:partial]
      form_code = render_partial(options[:partial]||options[:model].to_s.tableize+'_form')
    end
    code += content_tag(:div, form_code, :class=>'fields')
    code += content_tag(:div,submit_tag(l(options[:submit]||:submit))+ link_to(l(options[:cancel]||:cancel), :back), :class=>'actions')
    code += '</form>'
    code = title + content_tag(:div,code)
#    raise Exception.new params[:body_width].to_s+'/'+params[:body_width].class.to_s
    html_options = {:class=>'formalize'}
#    html_options[:style] = "width:"+session[:body_width].to_s+"px" if session[:body_width]
    html_options[:style] = "width:"+770.to_s+"px"
    content_tag(:div,code, html_options)
  end


  def formalize_lines(form)
    code = ''
    controller = self.controller
    # compute column number
    column_number = 0
    for line in form.lines
      case line[:nature]
      when :title 
        col = 1
      when :line
        col = (line[:params].size.to_f/3).round 
      end
      column_number = col if col>column_number
    end
    column_number *= 3

    # build HTML
    for line in form.lines
      klass = line[:nature].to_s
      
      # before line      
      code += content_tag(:tr, content_tag(:th,'', :colspan=>column_number), :class=>"before-title") if line[:nature]==:title
      
      # line
      line_code = ''
      case line[:nature]
      when :title
        reset_cycle "parity"
        line[:value] = l(controller.controller_name, controller.action_name,line[:value]) if line[:value].is_a? Symbol
        line_code += content_tag(:th,line[:value].to_s,:class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>column_number)
      when :line
        klass += ' '+cycle('odd','even', :name=>"parity")
        col = (line[:params].size.to_f/3).round
        col.times do |c|
          attribute = line[:params][c*3]
          field     = line[:params][c*3+1]
          options   = line[:params][c*3+2]||{}
          if field.is_a? Symbol
            model  = field.to_s.classify.constantize
            label  = model.human_attribute_name attribute.to_s
            column = model.columns_hash[attribute.to_s]
            input  = ''
            html_options = {}
            html_options[:size] = 24
            html_options[:class] = ''
            if column.nil?
              html_options[:class] += ' notnull' unless options[:null]!=false
              if attribute.to_s.match /password/
                html_options[:size] = 12
                options[:field] = :password if options[:field].nil?
              end
            else
              html_options[:class] += ' notnull' unless column.null
              unless column.limit.nil?
                html_options[:size] = column.limit if column.limit<html_options[:size]
                html_options[:maxlength] = column.limit
              end
            end
            case options[:field]
            when :password
              input = password_field field, attribute, html_options
            else
              input = text_field field, attribute, html_options
            end
          else
            label = l(controller.controller_name, controller.action_name, attribute)
            input = field
          end
          options[:example] = [options[:example]] if options[:example].is_a? String
          help  = ''
          help += content_tag(:div,l(:info, [content_tag(:span,options[:info].to_s)]), :class=>:info) if options[:info]
          help += content_tag(:div,l(:example, [content_tag(:span,options[:example])]), :class=>:example) if options[:example]
          help += content_tag(:div,l(:hint,[content_tag(:span,options[:hint].to_s)]), :class=>:hint) if options[:hint]
          label = content_tag(:acronym,label, :title=>options[:info]) if options[:info]

          help_options = {:class=>"help", :id=>options[:help_id]}
          help_options[:colspan] = 1+column_number-3*col if c==col-1 and 3*col<column_number


          label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
          input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
          help  = content_tag(:td, help,  help_options)
          line_code += label+input+help
        end
        (column_number-3*col).times{ line_code += content_tag(:td) }
      end
      code += content_tag(:tr, line_code, :class=>klass) unless line_code.blank?

      # after line
      code += content_tag(:tr, content_tag(:th,'', :colspan=>column_number), :class=>"after-title") if line[:nature]==:title

    end
    code = content_tag(:table, code, :class=>'formalize')
  end
  
  class FormDefinition
    attr_reader :lines

    def initialize()
      @lines = []
    end

    def title(value, options={})
      @lines << options.merge({:nature=>:title, :value=>value})
    end

    def line(*params)
      @lines << {:nature=>:line, :params=>params}
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

