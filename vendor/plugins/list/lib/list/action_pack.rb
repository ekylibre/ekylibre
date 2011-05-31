module List

  module ActionController

    def self.included(base) #:nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods

      # Permits to define and generate methods to manage dynamic 
      # table List
      def list(*args, &block)
        name, options = nil, {}
        name = args[0] if args[0].is_a? Symbol
        options = args[-1] if args[-1].is_a? Hash
        name ||= self.controller_name.to_sym
        model = (options[:model]||name).to_s.classify.constantize
        options[:controller_method_name] = "list#{'_'+name.to_s if name != self.controller_name.to_sym}"
        options[:view_method_name]       = "#{self.controller_name}_list_#{name}_tag"
        options[:records_variable_name]  = "@#{name}"
        table = List::Table.new(name, model, options)
        yield table
        class_eval(table.send(:generate_controller_method_code))
        ActionView::Base.send(:class_eval, table.send(:generate_view_method_code))
      end

    end

  end

  module ViewsHelper
    def list(*args)
      name, options = nil, {}
      name = args[0] if args[0].is_a? Symbol
      options = args[-1] if args[-1].is_a? Hash
      self.send("#{options[:controller]||self.controller_name}_list_#{name||self.controller_name}_tag")
    end
  end

end

ActionController::Base.send(:include, List::ActionController)
ActionView::Base.send(:include, List::ViewsHelper)


