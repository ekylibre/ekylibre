# coding: utf-8
module ActiveList

  module Definition

    class ActionColumn < AbstractColumn
      include ActiveList::Helpers

      def header_code
        "''".c
      end

      def operation(record = 'record_of_the_death')
        @options[:method] = :delete if @name.to_s == "destroy" and !@options.has_key?(:method)
        @options[:confirm] ||= :are_you_sure_you_want_to_delete if @name.to_s == "destroy" and !@options.has_key?(:confirm)
        @options[:if] ||= :destroyable? if @name.to_s == "destroy"
        @options[:if] ||= :editable? if @name.to_s == "edit"
        @options[:confirm] = :are_you_sure if @options[:confirm].is_a?(TrueClass)
        link_options = ""
        if @options[:confirm]
          link_options << ", 'data-confirm' => #{(@options[:confirm]).inspect}.tl"
        end
        if @options['data-method'] or @options[:method]
          link_options << ", :method => h('#{(@options['data-method']||@options[:method])}')"
        end
        action = @name
        format = @options[:format] ? ", :format => '#{@options[:format]}'" : ""
        if @options[:remote]
          raise StandardError, "Sure to use :remote ?"
          # remote_options = @options.dup
          # remote_options['data-confirm'] = "#{@options[:confirm].inspect}.tl".c unless @options[:confirm].nil?
          # remote_options.delete :remote
          # remote_options.delete :image
          # remote_options = remote_options.inspect.to_s
          # remote_options = remote_options[1..-2]
          # code  = "link_to_remote(#{image}"
          # code += ", {url: {action: "+@name.to_s+", id: "+record+".id"+format+"}"
          # code += ", "+remote_options+"}"
          # code += ", {title: #{action.inspect}.tl}"
          # code += ")"
        elsif @options[:actions]
          unless @options[:actions].is_a? Hash
            raise StandardError, "options[:actions] have to be a Hash."
          end
          cases = []
          for expected, url in @options[:actions]
            cases << record+"."+@name.to_s+" == " + expected.inspect + "\nlink_to(content_tag(:i) + h(#{url[:action].inspect}.tl)"+
              ", {"+(url[:controller] ? 'controller: :'+url[:controller].to_s+', ' : '')+"action: '"+url[:action].to_s+"', id: "+record+".id"+format+"}"+
              ", {:class => '#{@name}'"+link_options+"}"+
              ")\n"
          end

          code = "if "+cases.join("elsif ")+"end"
        else
          url = @options[:url] ||= {}
          url[:controller] ||= (@options[:controller] || "RECORD.class.name.tableize".c) # self.table.model.name.underscore.pluralize.to_s
          url[:action] ||= @name.to_s
          url[:id] ||= "RECORD.id".c
          url.delete_if{|k, v| v.nil?}
          url = "{" + url.collect{|k, v| "#{k}: " + urlify(v, record)}.join(", ")+format+"}"
          code = "{class: '#{@name}'"+link_options+"}"
          code = "link_to(content_tag(:i) + h('#{action}'.tl), "+url+", "+code+")"
        end
        if @options[:if]
          code = "if " + recordify!(@options[:if], record) + "\n" + code.dig + "end"
        end
        if @options[:unless]
          code = "unless " + recordify!(@options[:unless], record) + "\n" + code.dig + "end"
        end
        code.c
      end
    end

  end

end
