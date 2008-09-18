# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def menu_modules
    modules = [:index, :accountancy, :sales, :purchases, :stocks]
    code = ''
    a = []
    a << action_name.to_sym 
    a << self.controller.controller_name.to_sym
    for m in modules
      if a.include? m
        code += content_tag 'strong', l(:guide,m,:title)
      else
        code += link_to(l(:guide,m,:title), :controller=>:guide, :action=>m)+' '
      end
    end
    code
  end

  def formalize(options)
    title = ''
    title = content_tag('h1', l(@controller.controller_name, @controller.action_name,options[:title]), :class=>"title") unless options[:title].nil?
    code  = form_tag({},:multipart=>options[:multipart]||false)
    form_code = '[No Form]'
    if block_given?
      form = FormDefinition.new(self.controller,options[:model])
      yield form
      form_code = form.to_html
      form_code = content_tag('table', form_code, :class=>'formalize') if options[:model].nil?
    else
      form_code = "[Not Implemented]"
#      form_code = render_partial(model.to_s.tableize+'_form')
    end
    code += content_tag('div', form_code, :class=>'fields')
    code += content_tag('div',submit_tag(l(options[:submit]||'submit'))+ link_to(lc('cancel'), :back), :class=>'actions')
    code += '</form>'
    code = title + content_tag('div',code)
    content_tag('div',code,:class=>'formalize')
  end

  
  class FormDefinition
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::FormHelper
    include ArkanisDevelopment::SimpleLocalization::LocalizedApplication::ContextSensetiveHelpers

    def initialize(controller, model=nil)
      @controller = controller
      @model = model
      @lines = []
    end

    def title(value)
      @lines << {:nature=>:title, :value=>value}
    end

    def line(*params)
      @lines << {:nature=>:line, :params=>params}
    end

    def to_html
      code = ''
      # compute column number
      column_number = 0
      for line in @lines
        case line[:nature]
        when :title 
          col = 1
        when :line
          col = (line[:params].size.to_f/3).round 
        end
        column_number = col if col>column_number
      end
      column_number *= 3

      for line in @lines
        klass = line[:nature].to_s
        case line[:nature]
        when :title
          reset_cycle "parity"
          line[:value] = l(@controller.controller_name, @controller.action_name,line[:value]) if line[:value].is_a? Symbol
          line_code = content_tag('th',line[:value].to_s,:class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>column_number)
        when :line
          klass += ' '+cycle('odd','even', :name=>"parity")
          col = (line[:params].size.to_f/3).round-1
          for c in 0..col
            attribute = line[:params][c]
            field     = line[:params][c+1]
            options   = line[:params][c+2]||{}
            if field.is_a? Symbol
              model = field.to_s.classify.constantize
              label = model.human_attribute_name attribute.to_s
              column = model.columns_hash[attribute.to_s]
              input = ''
              html_options = {}
              html_options[:size] = 24
              html_options[:class] = ''
              if column.nil?
                html_options[:class] += ' notnull' unless options[:null]!=false
                if attribute.to_s.match /password/
                  html_options[:size] = 12
                  input = password_field field, attribute, html_options
                else
                  input = text_field field, attribute, html_options
                end
              else
                html_options[:class] += ' notnull' unless column.null
                unless column.limit.nil?
                  html_options[:size] = column.limit if column.limit<html_options[:size]
                  html_options[:maxlength] = column.limit
                end
                input = text_field field, attribute, html_options
              end
            else
              label = l(@controller.controller_name, @controller.action_name, attribute)
              input = field
            end
            options[:example] = [options[:example]] if options[:example].is_a? String
            hint  = ''
            hint += 'Ex.&nbsp;: '+options[:example].join(", ") if options[:example]
            hint += '<br/>'if hint!='' and options[:hint]
            hint += 'Astuce&nbsp;: '+options[:hint].to_s if options[:hint]
            hint += '<br/>'if hint!='' and options[:info]
            hint += 'Info.&nbsp;: '+options[:info].to_s if options[:info]

            label = content_tag('td', label, :class=>"label", :id=>options[:label_id])
            input = content_tag('td', input, :class=>"input", :id=>options[:input_id])
            hint  = content_tag('td', hint,  :class=>"hint",  :id=>options[:hint_id])
            line_code = label+input+hint
          end
        end
        code += content_tag('tr', line_code, :class=>klass) unless line_code.blank?
      end
      code
    end
  end


end

