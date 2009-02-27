# Dyli
module Dyli
  module Controller
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    
    module ClassMethods
      
      include ERB::Util
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
      
      
      def dyli(name, options = {}) #:nodoc:
        options = {:limit => 5,:attributes => [:name]}.merge(options)
        
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
          
          render :inline => "<%= dyli_result(@items,'"+search+"',"+options[:attributes].inspect+") %>"
        end
      end
      
    end   
  end
  
  module View
    
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
      dyli_completer(tf_name, tf_value, hf_name, hf_value, options, tag_options, completion_options)
    end
    
    
    def dyli_result(models, search, displays=[])
      # We can't assume dom_id(model) is available because the plugin does not require Rails 2 by now.
      prefix = models.first.class.name.underscore.tr('/', '_') unless models.empty?
      
      items = models.map do |model|
        
        li_id      = "#{prefix}_#{model.id}"
        li_content = displays.collect {|display| model.send(display)}.join(', ')
        
        content_tag('li', highlight(li_content, search.to_s) , :id => li_id)
      end
      content_tag('ul', items.uniq)
    end
    
    #   is explained above.
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
      
      return <<-HTML
       #{auto_complete_stylesheet unless completion_options[:skip_style]}    
       #{hidden_field_tag(hf_name, hf_value, :id => hf_id)}
       #{text_field_tag tf_name, tf_value, tag_options}
       #{content_tag("div", "", :id => "#{tf_id}_auto_complete", :class => "auto_complete")}
       #{auto_complete_field tf_id, completion_options}
     HTML
    end
    
    private
    
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
    
    #  def determine_tag_options(hf_id, tf_id, options, tag_options) #:nodoc:
    def determine_tag_options(hf_id,tf_id, options, tag_options) #:nodoc:
      tag_options.update({
                           :id      => tf_id,
                           # Cache the default text field value when the field gets focus.
                           :onfocus => 'if (this.dyli == undefined) {this.dyli = this.value}'
                           #:onfocus => 'if (this.model_auto_completer_cache == undefined) {this.model_auto_completer_cache = this.value}'
                         })
      
      
      tag_options[:onchange] = if options[:allow_free_text]
                                 "window.setTimeout(function () {if (this.value != this.dyli) {$('#{hf_id}').value = ''}}.bind(this), 200)"
                               else
                                 "window.setTimeout(function () {this.value = this.dyli}.bind(this), 200)"
                               end
      
      
      unless options[:submit_on_return]
        tag_options[:onkeypress] = 'return event.keyCode == Event.KEY_RETURN ? false : true'
      end
    end
    
    # Determines the actual completion options, taken into account the ones from
    # the user.
    def determine_completion_options(hf_id, options, completion_options) #:nodoc:
      # model_auto_completer does most of its work in the afterUpdateElement hook of the
      # standard autocompletion mechanism. Here we generate the JavaScript that goes there.
      completion_options[:after_update_element] = <<-JS.gsub(/\s+/, ' ')
      function(element, value) {
          var model_id = /#{options[:regexp_for_id]}/.exec(value.id)[1];
          $("#{hf_id}").value = model_id;
          element.dyli = element.value;
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
