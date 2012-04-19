# coding: utf-8
module List

  class Table

    # Add a new method in Table which permit to define data columns
    def action(name, options={})
      @columns << ActionColumn.new(self, name, options)
    end

  end

  class ActionColumn < Column

    def header_code
      "'ƒ'"
    end


    def operation0(record='record')
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
        url[:controller] ||= @options[:controller]||self.table.model.name.underscore.pluralize.to_sym
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




    def operation(record='record')
      link_options = ""
      link_options += ", :confirm=>::I18n.translate('labels.#{@options[:confirm]}')" unless @options[:confirm].nil?
      link_options += ", :method=>#{@options[:method].inspect}" if @options[:method].is_a? Symbol
      action = @name
      format = @options[:format] ? ", :format=>'#{@options[:format]}'" : ""
      if @options[:remote]
        raise Exception.new("Sure to use :remote ?")
        remote_options = @options.dup
        remote_options[:confirm] = ::I18n.translate('labels.'+@options[:confirm].to_s) unless @options[:confirm].nil?
        remote_options.delete :remote
        remote_options.delete :image
        remote_options = remote_options.inspect.to_s
        remote_options = remote_options[1..-2]
        code  = "link_to_remote(#{image}"
        code += ", {:url=>{:action=>:"+@name.to_s+", :id=>"+record+".id"+format+"}"
        code += ", "+remote_options+"}"
        code += ", {:title=>::I18n.translate('labels.#{action}')}"
        code += ")"
      elsif @options[:actions]
        raise Exception.new("options[:actions] have to be a Hash.") unless @options[:actions].is_a? Hash
        cases = []
        for a in @options[:actions]
          v = a[1][:action].to_s.split('_')[-1]
          cases << record+"."+@name.to_s+".to_s=="+a[0].inspect+"\ntool_to(::I18n.translate('labels.#{v}')"+
            ", {"+(a[1][:controller] ? ':controller=>:'+a[1][:controller].to_s+', ' : '')+":action=>'"+a[1][:action].to_s+"', :id=>"+record+".id"+format+"}"+
            ", {:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+link_options+", :title=>::I18n.translate('labels.#{v}')}"+
            ")\n"
        end

        code = "if "+cases.join("elsif ")+"end"
      else
        url = @options[:url] ||= {}
        url[:controller] ||= @options[:controller]||self.table.model.name.underscore.pluralize.to_sym
        url[:action] ||= @name
        url[:id] ||= "RECORD.id"
        url.delete_if{|k, v| v.nil?}
        url = "{"+url.collect{|k, v| ":#{k}=>"+(v.is_a?(String) ? v.gsub(/RECORD/, record) : v.inspect)}.join(", ")+format+"}"
        code = "{:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+link_options+", :title=>::I18n.translate('labels.#{action}')}"
        code = "tool_to(::I18n.translate('labels.#{action}'), "+url+", "+code+")"
      end
      code = "if ("+@options[:if].gsub('RECORD', record)+")\n"+code+"\n end" if @options[:if]
      code
    end




  end

end
