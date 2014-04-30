module Ekylibre::Record
  module Acts #:nodoc:
    module Protected #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Blocks update or destroy if necessary
        def protect(options={}, &block)
          options[:on] = [:update, :destroy] unless options[:on]
          for callback in [options[:on]].flatten
            method_name = "protected_on_#{callback}?".to_sym
            # if self.respond_to?(method_name)
            #   raise StandardError, "Cannot protect because a method #{method_name} is already defined."
            # end

            define_method(method_name, &block)

            code  = "def #{callback}able?\n"
            code << "  !#{method_name}\n"
            code << "end\n"
            
            if callback == :update
              code << "alias :editable? #{callback}able?\n"
            end

            # class_eval "before_#{callback} {|record| record.#{method_name} }"
            # class_eval "before_#{callback} :#{method_name}"

            class_eval code
          end
        end


      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Protected)
