# Dyse
module Ekylibre
  module Dyke
    module Dyse
      module Controller
        
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        
        module ClassMethods
          
          include ERB::Util
          include ActionView::Helpers::TagHelper
          include ActionView::Helpers::UrlHelper
          
          # Controller-side method

          def dyse(name, model, attribute=:name, options = {})
            attributes = options[:attributes]||[attribute]

            query = []
            parameters = ''
            if options[:conditions].is_a? Hash
              options[:conditions].each do |key, value| 
                query << model.to_s.pluralize+"."+key.to_s+'=?'
                parameters += ', ' + sanitize_conditions(value)
              end
            end
            code  = ""
            code += "def dyse_"+name.to_s+"\n"
            code += "  conditions = [#{query.join(' AND ').inspect+parameters}]\n"
            code += "  search = params[:#{model}][:search]\n"
            code += "  words = search.lower.split(/\\s+/)\n"
            code += "  if words.size>0\n"
            code += "    conditions[0] += ' AND ('\n"
            code += "    words.times do |index|\n"
            code += "      word = #{(options[:filter]||'%X%').inspect}.gsub('X', words[index])\n"
            code += "      conditions[0] += ' OR ' if index>0\n"
            code += "      conditions[0] += "+attributes.collect{|key| "LOWER(#{model.to_s.pluralize}.#{key}) LIKE ?"}.join(' OR ').inspect+"\n"
            code += "      conditions += ["+(["word"]*attributes.size).join(", ")+"]\n"
            code += "    end\n"
            code += "    conditions[0] += ')'\n"
            code += "  end\n"
            order =  ", :order=>"+attributes.collect{|key| "#{model.to_s.pluralize}.#{key} ASC"}.join(', ').inspect
            limit =  options[:limit] ? ", :limit=>"+options[:limit].to_s : ""
            partial = options[:partial]
            code += "  list = ''\n"
            code += "  for item in "+model.to_s.camelcase+".find(:all, :conditions=>conditions"+order+limit+")\n"
            code += "    content = "+attributes.collect{|attribute| "item.#{attribute}.to_s"}.join('+", "+')+"\n"
            if partial
              display = "render(:partial=>#{partial.inspect}, :locals =>{:record=>#{model.inspect}, :content=>content, :search=>search})"
            else
              display = "highlight(content, search)"
            end
            code += "    list += '<li id=\"#{model}_\#\{item.id\}\">'+#{display}+'<input type=\"hidden\" value=\#\{content.inspect\} id=\"record_\#\{item.id\}\"/></li>'\n"
            code += "  end\n"
            code += "  render :text=>'<ul>'+list+'</ul>'\n"
            code += "end\n"
            puts code

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
        
        #
        # def dyse_tag(object, association, options={}, tag_options={}, completion_options={})
        def dyse_tag(object, association, name=nil, options={}, tag_options={}, completion_options={})
          name ||= object.to_s+'_'+association.to_s
          object  = instance_variable_get("@#{object}") if object.is_a? Symbol
          #foreign_key  = object.class.reflect_on_association(association).primary_key_name
          
#          name = options[:dyse] || association.to_s
          
          tf_name  = "#{association}[search]"
          tf_value = nil
          
          hf_name  = "" # "#{object}[#{foreign_key}]"
          hf_value = nil # (real_object.send(foreign_key) rescue nil)
          options  = { :action => "dyse_#{name}"}.merge(options)
          # options[:id] = real_object.area_id unless real_object.new_record?
          
          completion_options[:skip_style] = true;
          
          dyse_completer(tf_name, tf_value, hf_name, hf_value, options, tag_options, completion_options)
        end


        # tag
        def dyse_completer(tf_name, tf_value, hf_name, hf_value, options={}, tag_options={}, completion_options={})
          options = {
            :regexp_for_id        => '(\d+)$',
            :append_random_suffix => true,
            :allow_free_text      => false,
            :submit_on_return     => false,
            :controller           => controller.controller_name,
            :action               => 'dyse_' + tf_name.sub(/\[/, '_').gsub(/\[\]/, '_').gsub(/\[?\]$/, ''),
            :after_update_element => 'Prototype.emptyFunction'
          }.merge(options)
          
          options[:submit_on_return] = options[:send_on_return] if options[:send_on_return]
          
          hf_id, tf_id = determine_field_ids(options)
          determine_tag_options(tf_name, tf_value, hf_id, tf_id, options, tag_options)
          determine_completion_options(tf_id, hf_id, options, completion_options)
          
          code  = hidden_field_tag(hf_name, hf_value, :id => hf_id)
          code << text_field_tag(tf_name, tf_value, tag_options)
          code << content_tag("div", " ", :id => "#{tf_id}_dyse_complete", :class => "dyse_complete")
          code << dyse_complete_field(tf_id, completion_options)
          code << dyse_complete_stylesheet unless completion_options[:skip_style]
          code
        end
        
        #
        def dyse_complete_field(field_id, options = {})
          
          function =  "var #{field_id}_dyse_completer = new Ajax.Autocompleter("
          function << "'#{field_id}', "
          function << "'" + (options[:update] || "#{field_id}_dyse_complete") + "',"
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

          javascript_tag(function)
        end
        
        
        private
        
        #
        def dyse_complete_stylesheet
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
          hf_id = 'dyse_hf'
          tf_id = 'dyse_tf'
          if options[:append_random_suffix]
            rand_id = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
            hf_id << "_#{rand_id}"
            # tf_id << "_#{rand_id}"
          end
          return hf_id, tf_id
        end
        
        #  
        def determine_tag_options(tf_name, tf_value, hf_id, tf_id, options, tag_options)
          tag_options.update({
                               :id      => tf_id,
                               # Cache the default text field value when the field gets focus.
                               # :onfocus => "this.value  = 4"
                               #:onfocus => "if (this.dyse == undefined) {this.dyse = this.value}"
                               # :onblur => remote_function(:update=> tf_id, :url => {:action => 'dyse_one_' + tf_name.sub(/\[/, '_').gsub(/\[\]/, '_').gsub(/\[?\]$/, ''), :tf => tf_id, :hf=> hf_id}, :with => "'search='+this.value")+";$('#{hf_id}').value= $('record').value;event.keyCode = Event.KEY_RETURN; $('#{tf_id}').size = ($('#{tf_id}').value.length > 128 ? 128 : $('#{tf_id}').value.length);"
                               
                             })


          #     tag_options[:onfocus] =  if  not options[:allow_free_text]
          #                                      "if (this.dyse == undefined) {this.dyse = this.value}"
          #                                     else
          #                                       "this.dyse = 2"
          #                                     end


          tag_options[:onchange] = if not options[:allow_free_text]             
                                     "window.setTimeout(function () {if (this.value != this.dyse) {$('#{hf_id}').value = ''} this.value=this.dyse;}.bind(this), 1000) "
                                   else
                                     # "window.setTimeout(function () {$('#{tf_id}').value = this.dyse},200)" #.bind(this), 200)"
                                   end
          
          
          # if the user presses the button return to validate his choice from the list of completion. 
          #       unless options[:submit_on_return]
          
          #            tag_options[:onkeypress] = 'if (event.keyCode == Event.KEY_RETURN && '+options[:resize].to_s+') {'+
          #              'this.value = this.dyse; }'
          #           end
          
        end

        
        # Determines the actual completion options, taken into account the ones from
        # the user.
        def determine_completion_options(tf_id, hf_id, options, completion_options) #:nodoc:
          
          # dyse_completer does most of its work in the afterUpdateElement hook of the
          # standard autocompletion mechanism. Here we generate the JavaScript that goes there.
          completion_options[:after_update_element] = <<-JS.gsub(/\s+/, ' ')
      function(element, value) {
          var model_id = /#{options[:regexp_for_id]}/.exec(value.id)[1];
          $("#{hf_id}").value = model_id;
          element.dyse=element.value; 
          element.size = (element.dyse.length > 50 ? 50 : element.dyse.length);               
          event.keyCode = Event.KEY_RETURN;
          JS
          #element.value;
          if options[:resize]
            completion_options[:after_update_element] += <<-JS.gsub(/\s+/, ' ')
             element.size = (element.dyse.length > 50 ? 50 : element.dyse.length);               
             JS
          end
          
          completion_options[:after_update_element] += <<-JS.gsub(/\s+/, ' ')
            (#{options[:after_update_element]})(element, value, $("#{hf_id}"), model_id);
            }
            JS
          
          
          # :url has higher priority than :action and :controller.
          completion_options[:url] = options[:url] || url_for(
                                                              :controller => options[:controller],
                                                              :action     => options[:action],
                                                              :real_object => options[:id]
                                                              )
          
        end
        
      end
      
    end

  end
end






