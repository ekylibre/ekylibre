module ActiveList

  module ActionPack

    module ActionController

      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Permits to define and generate methods to manage dynamic
        # table ActiveList
        def list(*args, &block)
          options = args.extract_options!
          options[:controller] = self
          args << options
          generator = ActiveList::Generator.new(*args, &block)
          class_eval(generator.controller_method_code, __FILE__, __LINE__)
          ActionView::Base.send(:class_eval, generator.view_method_code, __FILE__, __LINE__)
        end

      end

    end

    module ViewsHelper

      # Calls the generated view helper
      def list(*args, &block)
        options = args.extract_options!
        name = args.shift
        self.send("_#{options[:controller] || self.controller_name}_#{__method__}_#{name || self.controller_name}_tag", &block)
      end

    end

  end

end
