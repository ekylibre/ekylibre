#  Rails javascript
ActionView::Helpers::AssetTagHelper::register_javascript_include_default "rails"


# html_safe methods directly pasted from Rails 3
require 'erb'
require 'active_support/core_ext/kernel/singleton_class'

class ERB
  module Util
    # HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;' }
    # JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C' }

    # A utility method for escaping HTML tag characters.
    # This method is also aliased as <tt>h</tt>.
    #
    # In your ERb templates, use this method to escape any unsafe content. For example:
    #   <%=h @person.name %>
    #
    # ==== Example:
    #   puts html_escape("is a > 0 & a < 10?")
    #   # => is a &gt; 0 &amp; a &lt; 10?
    def html_escape(s)
      s = s.to_s
      if s.html_safe?
        s
      else
        s.gsub(/[&"><]/) { |special| HTML_ESCAPE[special] }.html_safe
      end
    end

    remove_method(:h)
    alias h html_escape

    module_function :h

    singleton_class.send(:remove_method, :html_escape)
    module_function :html_escape

    # A utility method for escaping HTML entities in JSON strings.
    # This method is also aliased as <tt>j</tt>.
    #
    # In your ERb templates, use this method to escape any HTML entities:
    #   <%=j @person.to_json %>
    #
    # ==== Example:
    #   puts json_escape("is a > 0 & a < 10?")
    #   # => is a \u003E 0 \u0026 a \u003C 10?
    def json_escape(s)
      s.to_s.gsub(/[&"><]/) { |special| JSON_ESCAPE[special] }
    end

    alias j json_escape
    module_function :j
    module_function :json_escape
  end
end

class Object
  def html_safe?
    false
  end
end

class Fixnum
  def html_safe?
    true
  end
end

module ActiveSupport #:nodoc:
  class SafeBuffer < String
    alias safe_concat concat

    def concat(value)
      if value.html_safe?
        super(value)
      else
        super(ERB::Util.h(value))
      end
    end
    alias << concat

    def +(other)
      dup.concat(other)
    end

    def html_safe?
      true
    end

    def html_safe
      self
    end

    def to_s
      self
    end

    def to_yaml(*args)
      to_str.to_yaml(*args)
    end
  end
end

class String
  def html_safe!
    raise "You can't call html_safe! on a String"
  end

  def html_safe
    ActiveSupport::SafeBuffer.new(self)
  end
end



# ModelName
class ::ActiveSupport::ModelName

  def human
    ::I18n.translate("activerecord.models.#{self.singular.underscore}")
  end

end

class ActiveRecord::Base
  @@callbacks_counter = 0

  class << self


    # Callbacks
    # Permits the use of callbacks like in Rails 3
    compat = :compatibility_with_rails3
    code = ""
    #  
    for callback in %w( before_validation validate after_validation )
      code += "def #{callback}_with_#{compat}(*args, &block)\n"
      code += "  options = args[-1].is_a?(::Hash) ? args[-1] : {}\n"
      code += "  raise ArgumentError.new(':on option in Callback must be one of these :save, :create or :update. '+options[:on].inspect+' got.') if options[:on] and not [:save, :create, :update].include?(options[:on])\n"
      code += "  moment = \"#{callback}\#\{[:create, :update].include?(options[:on]) ? '_on_'+options[:on].to_s : '_without_#{compat}'\}\".to_sym\n"
      code += "  return self.send(moment, *args, &block) if not block_given? or (block_given? and block.arity > 0)\n"
      code += "  method_name = \"\#\{moment\}_\#\{@@callbacks_counter+=1\}\".to_sym\n"
      code += "  self.send(moment, method_name)\n"
      code += "  self.send(:define_method, method_name, &block)\n"
      code += "end\n"
      code += "alias_method_chain :#{callback}, :#{compat}\n"
    end

    # before_validation_on_create after_validation_on_create before_validation_on_update after_validation_on_update
    for callback in %w( after_find after_initialize before_save after_save before_create after_create before_update after_update before_destroy after_destroy )
      moment = ":#{callback}_without_#{compat}"
      method_name = ":#{callback}_#{@@callbacks_counter+=1}"
      code += "def #{callback}_with_#{compat}(*args, &block)\n"
      code += "  return self.send(#{moment}, *args, &block) if not block_given? or (block_given? and block.arity > 0)\n"
      code += "  self.send(#{moment}, #{method_name})\n"
      code += "  self.send(:define_method, #{method_name}, &block)\n"
      code += "end\n"
      code += "alias_method_chain :#{callback}, :#{compat}\n"
    end

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    eval(code)


    # Human attribute name
    # Rails 3 style but not totally
    def human_attribute_name(attribute, options = {})
      #       defaults = lookup_ancestors.map do |klass|
      #         "#{self.i18n_scope}.attributes.#{klass.model_name.i18n_key}.#{attribute}".to_sym
      #       end
      
      defaults = ["activerecord.attributes.#{self.model_name.singular}.#{attribute}".to_sym]
      defaults << "attributes.#{attribute}".to_sym
      defaults << options.delete(:default) if options[:default]
      defaults << attribute.to_s.humanize
      
      options.reverse_merge! :count => 1, :default => defaults
      I18n.translate(defaults.shift, options)
    end


  end




end

