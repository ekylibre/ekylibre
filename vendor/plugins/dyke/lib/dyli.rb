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
          def dyli(name, options = {})
            options = {:limit => 5,:attributes => [:name], :partial => nil}.merge(options)
            
            if options[:model].nil?
              model = name.to_s.camelize.constantize
            else
              model = options[:model].to_s.camelize.constantize
            end
            
            raise Exception.new("The model specified does not exist.") unless ActiveRecord::Base.connection.tables.include? model.table_name
            
            define_method("dyli_#{name}") do
              conditions=[""]
              search=params[model.to_s.lower.to_sym][:search].chars.downcase
              conditions[0] = options[:attributes].collect do |attribute|
                conditions << '%'+search+'%'
                "LOWER(#{attribute}) LIKE ?"
              end.join(" OR ")
              
              find_options = { 
                :conditions => conditions,
                :order => "#{options[:attributes][0]} ASC",
                :limit => options[:limit]
              }
              
              @items = model.find(:all, find_options) 
              
              if options[:partial]
                render :inline => "<%= dyli_result(@items,'"+search+"',"+options[:attributes].inspect+","+options[:partial].inspect+") %>"
              else
                render :inline => "<%= dyli_result(@items,'"+search+"',"+options[:attributes].inspect+") %>"
              end
              
            end
          end
          
        end 
        
      end
      
      
      module View
        
        #
        def dyli_tag(object, association, options={}, tag_options={}, completion_options={})
          real_object  = instance_variable_get("@#{object}")
          foreign_key  = real_object.class.reflect_on_association(association).primary_key_name
          
          name = options[:dyli] || association.to_s
          
          tf_name  = "#{association}[search]"
          tf_value = nil
          
          hf_name  = "#{object}[#{foreign_key}]"
          hf_value = (real_object.send(foreign_key) rescue nil)
          options  = { :action => "dyli_#{name}"
          }.merge(options)
          
          completion_options[:skip_style] = true;
          
          dyli_completer(tf_name, tf_value, hf_name, hf_value, options, tag_options, completion_options)
        end
        
        #
        def dyli_result(models, search, displays=[], partial=nil)
          # We can't assume dom_id(model) is available because the plugin does not require Rails 2 by now.
          prefix = models.first.class.name.underscore.tr('/', '_') unless models.empty?
          
          items = models.map do |model|
            
            li_id      = "#{prefix}_#{model.id}"
            li_content = displays.collect {|display| model.send(display)}.join(', ')

            # if a partial is used or not to display the research.
            if partial
              content_tag('li', (render :partial => partial.to_s, :locals =>{:record=> model, :li_content => li_content, :search => search })+tag('input', :type =>'hidden', :value =>li_content, :id =>'record_'+model.id.to_s), :id => li_id)
            else
              content_tag('li', highlight(li_content, search)+tag('input', :type =>'hidden', :value =>li_content, :id =>'record_'+model.id.to_s), :id => li_id)
            end
            
          end
          
          content_tag('ul', items.uniq)
        end
        
        
        # tag
        def dyli_completer(tf_name, tf_value, hf_name, hf_value, options={}, tag_options={}, completion_options={})
          options = {
            :regexp_for_id        => '(\d+)$',
            :append_random_suffix => true,
            :allow_free_text      => false,
            :submit_on_return     => false,
            :controller           => controller.controller_name,
            :action               => 'dyli_' + tf_name.sub(/\[/, '_').gsub(/\[\]/, '_').gsub(/\[?\]$/, ''),
            :after_update_element => 'Prototype.emptyFunction'
          }.merge(options)
          options[:submit_on_return] = options[:send_on_return] if options[:send_on_return]
          
          hf_id, tf_id = determine_field_ids(options)
          determine_tag_options(hf_id, tf_id, options, tag_options)
          determine_completion_options(hf_id, options, completion_options)
          #raise Exception.new(completion_options[:after_update_element].inspect)
          return <<-HTML
       #{dyli_complete_stylesheet unless completion_options[:skip_style]}    
       #{hidden_field_tag(hf_name, hf_value, :id => hf_id)}
       #{text_field_tag(tf_name, tf_value, tag_options)}
       #{content_tag("div", " ", :id => "#{tf_id}_dyli_complete", :class => "dyli_complete")}
       #{dyli_complete_field tf_id, completion_options}
     HTML
        end
        

        def dyli_complete_field(field_id, options = {})
          function =  "var #{field_id}_dyli_completer = new Ajax.Autocompleter("
          function << "'#{field_id}', "
          function << "'" + (options[:update] || "#{field_id}_dyli_complete") + "', "
          function << "'#{url_for(options[:url])}'"
          
          js_options = {}
          js_options[:tokens] = array_or_string_for_javascript(options[:tokens]) if options[:tokens]
          js_options[:callback]   = "function(element, value) { return #{options[:with]} }" if options[:with]
          js_options[:indicator]  = "'#{options[:indicator]}'" if options[:indicator]
          js_options[:select]     = "'#{options[:select]}'" if options[:select]
          js_options[:paramName]  = "'#{options[:param_name]}'" if options[:param_name]
          js_options[:frequency]  = "#{options[:frequency]}" if options[:frequency]
          js_options[:method]     = "'#{options[:method].to_s}'" if options[:method]

          { :after_update_element => :afterUpdateElement, 
            :on_show => :onShow, :on_hide => :onHide, :min_chars => :minChars }.each do |k,v|
            js_options[v] = options[k] if options[k]
          end

          function << (', ' + options_for_javascript(js_options) + ')')

          javascript_tag(function)
        end
        
        
        private
        
        def dyli_complete_stylesheet
          content_tag('style', <<-EOT, :type => Mime::CSS)
        div.dyli_complete {
          width: 350px;
        }
        div.dyli_complete ul {
          position: fixed; 
          border:1px solid #888;
          margin:0;
          padding:0;
          width:30%;
          list-style-type:none;
        }
        div.dyli_complete ul li {
          background-color: #B1D1F9;
          margin:0;
          padding:3px;
        }
        div.dyli_complete ul li.selected {
          background-color: #C9D7F1;
        }
        div.dyli_complete ul strong.highlight {
          color: #800; 
          margin:0;
          padding:0;
        }
      EOT
        end
        
        #
        def determine_field_ids(options)
          hf_id = 'dyli_hf'
          tf_id = 'dyli_tf'
          if options[:append_random_suffix]
            rand_id = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
            hf_id << "_#{rand_id}"
            tf_id << "_#{rand_id}"
          end
          return hf_id, tf_id
        end
        
        #  
        def determine_tag_options(hf_id,tf_id, options, tag_options)
          tag_options.update({
                               :id      => tf_id,
                               # Cache the default text field value when the field gets focus.
                               :onfocus => 'if (this.dyli == undefined) {this.dyli = this.value}',
                             })
          
          tag_options[:onchange] = if options[:allow_free_text]
                                     "window.setTimeout(function () {if (this.value != this.dyli) {$('#{hf_id}').value = ''}}.bind(this), 200)"
                                   else
                                     "window.setTimeout(function () {this.value = this.dyli}.bind(this), 200)"
                                   end
          
          # if the user presses the button return to validate his choice from the list of completion. 
           unless options[:submit_on_return]
            tag_options[:onkeypress] = 'if (event.keyCode == Event.KEY_RETURN && '+options[:resize].to_s+') {'+
              'this.size = (this.dyli.length > 128 ? 128 : this.dyli.length);'+
              'this.value = this.dyli; }'
          end
          
        end

        
        # Determines the actual completion options, taken into account the ones from
        # the user.
        def determine_completion_options(hf_id, options, completion_options) #:nodoc:
          # dyli_completer does most of its work in the afterUpdateElement hook of the
          # standard autocompletion mechanism. Here we generate the JavaScript that goes there.
          completion_options[:after_update_element] = <<-JS.gsub(/\s+/, ' ')
      function(element, value) {
          var model_id = /#{options[:regexp_for_id]}/.exec(value.id)[1];
          $("#{hf_id}").value = model_id;
          element.dyli = document.getElementById('record_'+model_id).value;
          JS
        
          
          if options[:resize]
            completion_options[:after_update_element] += <<-JS.gsub(/\s+/, ' ')
             element.size = (element.dyli.length > 128 ? 128 : element.dyli.length);               
             JS
          end
 
          completion_options[:after_update_element] += <<-JS.gsub(/\s+/, ' ')
            (#{options[:after_update_element]})(element, value, $("#{hf_id}"), model_id);
            }
            JS
          
          
          # :url has higher priority than :action and :controller.
          completion_options[:url] = options[:url] || url_for(
                                                              :controller => options[:controller],
                                                              :action     => options[:action]
                                                              )
          
        end
        
        
      end
      
    end

  end
end






