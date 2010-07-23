module ActiveRecord
  module Acts #:nodoc:
    module Checkable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      # This +acts_as+ extension permits to stop a destruction of an object unless it is checkable (if the record respond to "checkable?")
      module ClassMethods
        def self.extended(base)
          class << base
            alias_method_chain :allocate, :acts_as_checkable
            alias_method_chain :new, :acts_as_checkable
            alias_method_chain :inherited, :acts_as_checkable
          end
        end
        
        def inherited_with_acts_as_checkable(child)
          load_acts_as_checkable unless self == ::ActiveRecord::Base
          inherited_without_acts_as_checkable(child)
        end
        
        def allocate_with_acts_as_checkable
          load_acts_as_checkable
          allocate_without_acts_as_checkable
        end

        def new_with_acts_as_checkable(*args)
          load_acts_as_checkable
          new_without_acts_as_checkable(*args) { |*block_args| yield(*block_args) if block_given? }
        end

        protected

        def load_acts_as_checkable
          # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
          return if @acts_as_checkable_loaded || self.abstract_class? || (self!=base_class) || name.blank? || !table_exists?
          @acts_as_checkable_loaded = true
          code = ""
          if self.respond_to?(:destroyable?)
            code += "before_destroy {|record| return false unless self.destroyable? }\n"
          end
          if self.respond_to?(:updatable?)
            code += "before_update  {|record| return false unless self.updatable? }\n"
          end
          if self.respond_to?(:clean)
            code += "before_validation  {|record| record.clean }\n"
          end
          if self.respond_to?(:check)
            code += "validate  {|record| record.check }\n"
          end
          if self.respond_to?(:check_on_update)
            code += "validate_on_update  {|record| record.check_on_update }\n"
          end
          if self.respond_to?(:check_on_create)
            code += "validate_on_create  {|record| record.check_on_create }\n"
          end
          class_eval code
        end

      end

    end
  end
end
