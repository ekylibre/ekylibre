module Kame

  module ActionController

    def self.included(base) #:nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods

      # Permits to define and generate methods to manage dynamic 
      # table Kame
      def create_kame(name, options={}, &block)
        model = (options[:model]||name).to_s.classify.constantize
        table = Kame::Table.new(name, model, options)
        yield table
        class_eval(table.generate_controller_method_code)
        ActionView::Base.send :class_eval, table.generate_view_method_code
      end

    end

  end

  module ActionView
    def kame(name)
      self.send(Kame.view_method_name(name))
    end
  end

end
