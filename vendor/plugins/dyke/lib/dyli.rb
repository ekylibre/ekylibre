# Dyli
module Ekylibre
  module Dyke
    module Dyli
      module Controller
        
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        
        module ClassMethods
          
          include ERB::Util
          include ActionView::Helpers::TagHelper
          include ActionView::Helpers::UrlHelper
          
          #
          def dyli(name_db, attributes=:name, options={})
            model = (options[:model]||name_db).to_s.singularize.camelize.constantize
            attributes = [attributes] unless attributes.is_a? Array
            attributes_hash = {}
            0..attributes.size.times do |i|
              attribute = attributes[i]
              attributes[i] = attribute.is_a?(Symbol) ? model.table_name+'.'+attribute.to_s : attribute.to_s
              attributes_hash['att'+i.to_s] = attributes[i]
            end
            
            query = []
            parameters = ''
            if options[:conditions].is_a? Hash
              options[:conditions].each do |key, value| 
                query << (key.is_a?(Symbol) ? model.table_name+"."+key.to_s : key.to_s)+'=?'
                parameters += ', ' + sanitize_conditions(value)
              end
            elsif options[:conditions].is_a? Array
              conditions = options[:conditions]
              case conditions[0]
              when String  # SQL
#               query << '["'+conditions[0].to_s+'"'
                query << conditions[0].to_s
                parameters += ', '+conditions[1..-1].collect{|p| sanitize_conditions(p)}.join(', ') if conditions.size>1
#                query << ')'
              else
                raise Exception.new("First element of an Array can only be String or Symbol.")
              end
            end
            
            method_name = name_db.to_s+'_dyli'

            code  = ""
            code += "def #{method_name}\n"
            code += "  conditions = [#{query.join(' AND ').inspect+parameters}]\n"
            # code += "  raise Exception.new(params.inspect)\n"
            code += "  search = params[:#{name_db}][:search]||\"\"\n"
            code += "  words = search.lower.split(/[\\s\\,]+/)\n"
            code += "  if words.size>0\n"
            code += "    conditions[0] += '#{' AND ' if query.size>0}('\n"
            code += "    words.size.times do |index|\n"
            code += "      word = #{(options[:filter]||'%X%').inspect}.gsub('X', words[index])\n"
            code += "      conditions[0] += ') AND (' if index>0\n"
            code += "      conditions[0] += "+attributes.collect{|key| "LOWER(#{key}) LIKE ?"}.join(' OR ').inspect+"\n"
            code += "      conditions += ["+(["word"]*attributes.size).join(", ")+"]\n"
            code += "    end\n"
            code += "    conditions[0] += ')'\n"
            code += "  end\n"
            select = (model.table_name+".id AS id, "+attributes_hash.collect{|k,v| v+" AS "+k}.join(", ")).inspect
            order = ", :order=>"+attributes.collect{|key| "#{key} ASC"}.join(', ').inspect
            limit = ", :limit=>"+(options[:limit]||12).to_s
            joins = options[:joins] ? ", :joins=>"+options[:joins].inspect : ""
            partial = options[:partial]
            code += "  list = ''\n"
            code += "  for item in "+model.to_s+".find(:all, :select=>#{select}, :conditions=>conditions"+joins+order+limit+")\n"
            code += "    content = "+attributes_hash.collect{|attribute, v| "item.#{attribute}.to_s"}.join('+", "+')+"\n"
            if partial
              display = "render(:partial=>#{partial.inspect}, :locals =>{:record=>item, :content=>content, :search=>search})"
            else
              display = "highlight(content, search)"
            end
            code += "    list += \"<li id=\\\"#{name_db}_\#\{item.id\}\\\">\"+#{display}+\"<input type=\\\"hidden\\\" value=\#\{content.inspect\} id=\\\"record_\#\{item.id\}\\\"/></li>\"\n"
            code += "  end\n"
            code += "  render :text=>'<ul>'+list+'</ul>'\n"
            code += "end\n"

            module_eval(code)
          end
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
      
      
      module View
 
        # Acts like select_tag
        def dyli_tag(name_html, name_db, options={}, tag_options={}, completion_options={})
          tf_name  = "#{name_db}[search]"
          tf_value = nil
          hf_name  = "#{name_html}"
          hf_value = nil
          options  = {:action => "#{name_db}_dyli"}.merge(options)
          if options[:value].is_a? ActiveRecord::Base
            foreign = options[:value]
            tf_value = foreign.send([:label, :name, :code, :inspect].detect{|a| foreign.respond_to? a})
            hf_value = foreign.id
          end

          options[:field_id] = name_html.gsub(/[\[\]]/,'_').gsub(/(^\_+|\_+$)/, '')
          completion_options[:skip_style] = true;
          
          dyli_completer(tf_name, tf_value, hf_name, hf_value, options, tag_options, completion_options)
        end
 
       
        # Acts like select
        def dyli(object, association, name_db, options={}, tag_options={}, completion_options={})
          real_object = instance_variable_get("@#{object}")
          association = association.to_s[0..-4].to_sym if association.to_s.match(/_id$/)
          reflection  = real_object.class.reflect_on_association(association)
          raise Exception.new("Unknown reflection #{association} for #{real_object.class}") if reflection.nil?
          foreign_key = reflection.primary_key_name
                    
          name = name_db || association.to_s
          
          foreign = real_object.send(association)
          tf_name  = "#{name_db}[search]"
          tf_value = foreign ? foreign.send([:label, :name, :code, :inspect].detect{|a| foreign.respond_to? a}) : ''
          
          hf_name  = "#{object}[#{foreign_key}]"
          hf_value = (real_object.send(foreign_key) rescue nil)
          options  = { :action => "#{name}_dyli"}.merge(options)
          options[:real_object] = real_object.send(foreign_key) unless real_object.new_record?
          options[:field_id] = "#{object}_#{foreign_key}"
           
          completion_options[:skip_style] = true;
          
          dyli_completer(tf_name, tf_value, hf_name, hf_value, options, tag_options, completion_options)
        end
        
        
        # tag
        def dyli_completer(tf_name, tf_value, hf_name, hf_value, options={}, tag_options={}, completion_options={})
          options = {
            :regexp_for_id        => '(\d+)$',
            :append_random_suffix => true,
            :allow_free_text      => false,
            :submit_on_return     => false,
            :controller           => controller.controller_name,
            :action               => tf_name.sub(/\[/, '_').gsub(/\[\]/, '_').gsub(/\[?\]$/, '') + '_dyli',
            :after_update_element => 'Prototype.emptyFunction'
          }.merge(options)
          
          options[:submit_on_return] = options[:send_on_return] if options[:send_on_return]
          
          hf_id = options[:field_id]
          tf_id = "tf_"+hf_id
          #hf_id, tf_id = determine_field_ids(options)
          # determine_tag_options(tf_name, tf_value, hf_id, tf_id, options, tag_options)
          # determine_completion_options(tf_id, hf_id, options, completion_options)
          determine_tag_options(hf_id, tf_id, options, tag_options)
          determine_completion_options(hf_id, tf_id, options, completion_options)
     
          return <<-HTML
          #{dyli_complete_stylesheet unless completion_options[:skip_style]}    
          #{hidden_field_tag(hf_name, hf_value, :id => hf_id)}
          #{text_field_tag(tf_name, tf_value, tag_options)}
          #{content_tag("div", " ", :id => "#{tf_id}_dyli_complete", :class => "dyli_complete")}
          #{dyli_complete_field(tf_id, completion_options)}
          HTML
        end
        
        #
        def dyli_complete_field(field_id, options = {})
          
          function =  "var #{field_id}_dyli_completer = new Ajax.Autocompleter("
          function << "'#{field_id}', "
          function << "'" + (options[:update] || "#{field_id}_dyli_complete") + "',"
          function << "'#{url_for(options[:url])}'"
          
          js_options = {}
          js_options[:tokens] = array_or_string_for_javascript(options[:tokens]) if options[:tokens]
          js_options[:callback]   = "function(element, value) { return #{options[:with]} }" if options[:with]
          js_options[:indicator]  = "'#{options[:indicator]}'" if options[:indicator]
          js_options[:select]     = "'#{options[:select]}'" if options[:select]
          js_options[:paramName]  = "'#{options[:param_name]}'" if options[:param_name]
          js_options[:frequency]  = "'#{options[:frequency]}'" if options[:frequency]
          js_options[:method]     = "'#{options[:method].to_s}'" if options[:method]

          { :after_update_element => :afterUpdateElement, 
            :on_show => :onShow, :on_hide => :onHide, :min_chars => :minChars }.each do |k,v|
            js_options[v] = options[k] if options[k]
          end

          function << (', ' + options_for_javascript(js_options) + ')')
          
          return javascript_tag(function)
        end
        
        
        private
        
        #
        def dyli_complete_stylesheet
          content_tag('style', <<-EOT, :type => Mime::CSS)
        div.dyse_complete { width: 350px; }
        div.dyse_complete ul { position: fixed; margin:0; padding:0; width:30%; list-style-type:none; }
        div.dyse_complete ul li { background-color: #B1D1F9; margin:0; padding:3px; }
        div.dyse_complete ul li.selected { background-color: #C9D7F1; }
        div.dyse_complete ul strong.highlight { color: #800; margin:0; padding:0; }
      EOT
        end
        
        #
        def determine_field_ids(options)
          hf_id = 'dyli_hf'
          tf_id = 'dyli_tf'
          if options[:append_random_suffix]
            random_suffix = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
            random_suffix = Time.now.to_i.to_s(36)+rand.to_s[2..-1].to_i.to_s(36)
            hf_id << "_#{random_suffix}"
            tf_id << "_#{random_suffix}"
          end
         return hf_id, tf_id
        end
        


        def determine_tag_options(hf_id, tf_id, options, tag_options) #:nodoc:
          tag_options.update({
                               :id      => tf_id,
                               # Cache the default text field value when the field gets focus.
                               :onfocus => 'if (this.dyli_cache == undefined) {this.dyli_cache = this.value}'
                             })
          
          # When the user is done editing the text field we need to check its consistency. To be
          # able to do that we add an onchange event handler to the text field.
          #
          # When the user clicks with the mouse on the completion list there's a race
          # condition: model_auto_completer is assigned to in a callback, and this
          # handler is invoked, which uses the cache as well. This often resulted in
          # corrupt strings if the user selected two models with the mouse. That's
          # why we use a small delay. Looks like 200 milliseconds are enough.
          tag_options[:onchange] = if options[:allow_free_text]
                                     "window.setTimeout(function () {if (this.value != this.dyli_cache) {$('#{hf_id}').value = ''}}.bind(this), 200)"
                                   else
                                     "window.setTimeout(function () {this.value = this.dyli_cache}.bind(this), 200)"
                                   end
          
          unless options[:submit_on_return]
            tag_options[:onkeypress] = 'return event.keyCode == Event.KEY_RETURN ? false : true'
          end
          tag_options[:class] = 'dyli'
        end
        
        # Determines the actual completion options, taken into account the ones from
        # the user.
        def determine_completion_options(hf_id, tf_id, options, completion_options) #:nodoc:
          # model_auto_completer does most of its work in the afterUpdateElement hook of the
          # standard autocompletion mechanism. Here we generate the JavaScript that goes there.
          resize = options[:no_resize] ? "" : "element.size = (element.dyli_cache.length > 64 ? 64 : element.dyli_cache.length);"
          completion_options[:after_update_element] = <<-JS.gsub(/\s+/, ' ')
          function(element, value) {
            var model_id = /#{options[:regexp_for_id]}/.exec(value.id)[1];
            $("#{hf_id}").value = model_id;
            element.dyli_cache = element.value;
            #{resize}
            (#{options[:after_update_element]})(element, value, $("#{hf_id}"), model_id);
          }
          JS
          
          # :url has higher priority than :action and :controller.
          completion_options[:url] = options[:url] || url_for(:controller => options[:controller], :action => options[:action])
          completion_options
        end
        
      end
      
    end

  end
end






