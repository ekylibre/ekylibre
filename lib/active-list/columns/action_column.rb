# coding: utf-8
module ActiveList

  class Table

    # Add a new method in Table which permit to define data columns
    def action(name, options = {})
      @columns << ActionColumn.new(self, name, options)
    end

  end

  class ActionColumn < Column

    def header_code
      "''"
    end


    def operation(record = 'record')
      @options[:method] = :delete if @name.to_s == "destroy" and !@options.has_key?(:method)
      @options[:confirm] = :are_you_sure_you_want_to_delete if @name.to_s == "destroy" and !@options.has_key?(:confirm)
      link_options = ""
      if @options['data-confirm'] or @options[:confirm]
        link_options << ", 'data-confirm' => ::I18n.translate('labels.#{@options['data-confirm']||@options[:confirm]}')"
      end
      if @options['data-method'] or @options[:method]
        link_options << ", :method => h('#{(@options['data-method']||@options[:method])}')"
      end
      action = @name
      format = @options[:format] ? ", :format=>'#{@options[:format]}'" : ""
      if @options[:remote]
        raise Exception.new("Sure to use :remote ?")
        remote_options = @options.dup
        remote_options['data-confirm'] = ::I18n.translate('labels.'+@options[:confirm].to_s) unless @options[:confirm].nil?
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
          cases << record+"."+@name.to_s+".to_s=="+a[0].inspect+"\nlink_to(content_tag(:i) + h(::I18n.translate('labels.#{v}'))"+
            ", {"+(a[1][:controller] ? ':controller=>:'+a[1][:controller].to_s+', ' : '')+":action=>'"+a[1][:action].to_s+"', :id=>"+record+".id"+format+"}"+
            # ", {:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+link_options+"}"+
            ", {:class=>'#{@name}'"+link_options+"}"+
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
        # code = "{:id=>'"+@name.to_s+"_'+"+record+".id.to_s"+link_options+"}"
        code = "{:class=>'#{@name}'"+link_options+"}"
        code = "link_to(content_tag(:i) + h(::I18n.translate('labels.#{action}')), "+url+", "+code+")"
      end
      if @options[:if]
        code = "if (" + (@options[:if].is_a?(Symbol) ? "#{record}.#{@options[:if]}" : @options[:if].to_s.gsub('RECORD', record)) + ")\n" + code + "\n end" 
      end
      if @options[:unless]
        code = "unless (" + (@options[:unless].is_a?(Symbol) ? "#{record}.#{@options[:unless]}" : @options[:unless].to_s.gsub('RECORD', record)) + ")\n" + code + "\n end" 
      end
      code
    end




  end

end
