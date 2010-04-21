
class Formalize
  attr_reader :lines

  def initialize()
    @lines = []
  end

  def title(value, options={})
    @lines << options.merge({:nature=>:title, :value=>value})
  end

  def field(*params)
    line = params[2]||{}
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


module FormalizeHelper

  def formalize(options={})
    if block_given?
      form = Formalize.new
      yield form
      formalize_lines(form, options)
    else
      '[EmptyFormalizeError]'
    end
  end


  protected

  # This methods build a form line after line
  def formalize_lines(form, form_options)
    code = ''
    controller = self.controller
    xcn = 2
    
    # build HTML
    for line in form.lines
      css_class = line[:nature].to_s
      
      # line
      line_code = ''
      case line[:nature]
      when :error
        line_code += content_tag(:td, error_messages(line[:params].to_s), :class=>"error", :colspan=>xcn)
      when :title
        if line[:value].is_a? Symbol
          calls = caller
          file = calls[3].split(/\:\d+\:/)[0].split('/')[-1].split('.')[0]
          line[:value] = t("views.#{controller.controller_name}.#{file}.#{line[:value]}") 
        end
        line_code += content_tag(:th,line[:value].to_s, :class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>xcn)
      when :field
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
      
    end
    code = content_tag(:table, code, :class=>'formalize',:id=>form_options[:id])
    return code
  end



  def line_fragments(line)
    fragments = {}


    #     help_tags = [:info, :example, :hint]
    #     help = ''
    #     for hs in help_tags
    #       line[hs] = translate_help(line, hs)
    #       #      help += content_tag(:div,l(hs, [content_tag(:span,line[hs].to_s)]), :class=>hs) if line[hs]
    #       help += content_tag(:div,t(hs), :class=>hs) if line[hs]
    #     end
    #     fragments[:help] = help

    #          help_options = {:class=>"help", :id=>options[:help_id]}
    #          help_options[:colspan] = 1+xcn-xcn*col if c==col-1 and xcn*col<xcn
    #label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
    #input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
    #help  = content_tag(:td, help,  :class=>"help",  :id=>options[:help_id])

    if line[:model] and line[:attribute]
      record  = line[:model]
      method  = line[:attribute]
      options = line

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
      html_options[:class] = options[:class].to_s
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
        options[:field] = :checkbox if column.type==:boolean
        if column.type==:date
          options[:field] = :date 
          html_options[:size] = 10
        end
      end

      options[:options] ||= {}
      
      if options[:choices].is_a? Hash
        # options[:choices] = options[:choices].to_a.sort{|a,b| a[1]<=>b[1]}.collect{|x| x.reverse}
        options[:field] = :dyselect
        html_options.delete :size
        html_options.delete :maxlength
        html_options[:id] = "dyse"+rand.to_s[2..-1].to_i.to_s(36)
      end
      if options[:choices].is_a? Array
        options[:field] = :select if options[:field]!=:radio
        html_options.delete :size
        html_options.delete :maxlength
      end
      if options[:choices].is_a? Symbol
        options[:field] = :dyli
        html_options.delete :size
        html_options.delete :maxlength
        options[:options][:field_id] = "dyli"+rand.to_s[2..-1].to_i.to_s(36)
      end

      input = case options[:field]
              when :password
                password_field(record, method, html_options)
              when :label
                record.send(method)
              when :checkbox
                check_box(record, method, html_options)
              when :select
                options[:choices].insert(0,[options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
                select(record, method, options[:choices], options[:options], html_options)
              when :dyselect
                select(record, method, @current_company.reflection_options(options[:choices]), options[:options], html_options)
              when :dyli
                dyli(record, method, options[:choices], options[:options], html_options)
              when :radio
                options[:choices].collect{|x| radio_button(record, method, x[1])+"&nbsp;"+content_tag(:label, x[0], :for=>input_id+'_'+x[1].to_s)}.join(" ")
              when :textarea
                text_area(record, method, :cols => options[:options][:cols]||30, :rows => options[:options][:rows]||3, :class=>(options[:options][:cols]==80 ? :code : nil))
              when :date
                calendar_field(record, method)
              else
                text_field(record, method, html_options)
              end

      if options[:new].is_a?(Hash) and [:select, :dyselect, :dyli].include?(options[:field])
        label = tg(options[:new].delete(:label)||:new)
        if options[:field] == :select
          input += link_to(label, options[:new], :class=>:fastadd, :confirm=>::I18n.t('notifications.you_will_lose_all_your_current_data'))          
        else
          if options[:field] == :dyselect
            data = "refreshList('#{html_options[:id]}', '#{url_for(options[:choices].merge(:controller=>:company, :action=>:formalize))}', request);"
          else
            data = "refreshAutoList('#{options[:options][:field_id]}', request);"
          end
          data = ActiveSupport::Base64.encode64(Marshal.dump(data))
          input += link_to_function(label, "openDialog('#{url_for(options[:new].merge(:formalize=>data))}')", :href=>url_for(options[:new]), :class=>:fastadd)
        end
      end
      
      label = t("activerecord.attributes.#{object.class.name.underscore}.#{method.to_s}")
      label = " " if options[:options][:hide_label] 
      
      #      label = if object.class.methods.include? "human_attribute_name"
      #                object.class.human_attribute_name(method.to_s)
      #              elsif record.is_a? Symbol
      #                t("activerecord.attributes.#{object.class.name.underscore}.#{method.to_s}")
      #              else
      #                tg(method.to_s)
      #              end          
      label = content_tag(:label, label, :for=>input_id) if object!=record
    elsif line[:field]
      label = line[:label]||'[NoLabel]'
      if line[:field].is_a? Hash
        options = line[:field].dup
        options[:options]||={}
        datatype = options.delete(:datatype)
        name  = options.delete(:name)
        value = options.delete(:value)
        input = case datatype
                when :boolean
                  hidden_field_tag(name, "0")+check_box_tag(name, "1", value, options)
                when :string
                  size = (options[:size]||0).to_i
                  if size>64
                    text_area_tag(name, value, :id=>options[:id], :maxlength=>size, :cols => 30, :rows => 3)
                  else
                    text_field_tag(name, value, :id=>options[:id], :maxlength=>size, :size=>size)
                  end
                when :radio
                  options[:choices].collect{ |x| radio_button_tag('radio', (x[1].eql? true) ? 1 : 0, false, :id=>'radio_'+x[1].to_s)+"&nbsp;"+content_tag(:label,x[0]) }.join(" ")
                when :choice
                  options[:choices].insert(0,[options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
                  content = select_tag(name, options_for_select(options[:choices], value), :id=>options[:id])
                  if options[:new].is_a? Hash
                    content += link_to(tg(options[:new].delete(:label)||:new), options[:new], :class=>:fastadd)
                  end
                  content
                when :record
                  model = options[:model]
                  instance = model.new
                  method_name = [:label, :native_name, :name, :to_s, :inspect].detect{|x| instance.respond_to?(x)}
                  choices = model.find_all_by_company_id(@current_company.id).collect{|x| [x.send(method_name), x.id]}
                  select_tag(name, options_for_select([""]+choices, value), :id=>options[:id])
                when :date
                  date_select(name, value, :start_year=>1980)
                when :datetime
                  datetime_select(name, value, :default=>Time.now, :start_year=>1980)
                else
                  text_field_tag(name, value, :id=>options[:id])
                end
        
      else
        input = line[:field].to_s
      end
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
      t = tc(options[nature])
    elsif options[nature].is_a? String
      t = options[nature]
    end
    return t
  end
  

end
