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
          options[:on] = [options[:on]] unless options[:on].is_a?(Array)
          for callback in options[:on]
            method_name = "#{callback}able?".to_sym
            raise Exception, "Cannot protect because a method #{method_name} is already defined." if self.respond_to?(method_name)
            define_method method_name, &block
            class_eval "before_#{callback} {|record| record.#{method_name} }"
          end
        end


      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Protected)
