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
          if self.instance_methods.include?("destroyable?")
            code += "before_destroy {|record| return false unless self.destroyable? }\n"
          end
          if self.instance_methods.include?("updatable?")
            code += "before_update {|record| return false unless self.updatable? }\n"
          end
          if self.instance_methods.include?("prepare")
            code += "before_validation :prepare\n"
          end
          if self.instance_methods.include?("prepare_on_create")
            code += "before_validation(:on=>:create) do\n"
            code += "  prepare_on_create\n"
            code += "end\n"
          end
          if self.instance_methods.include?("prepare_on_update")
            code += "before_validation(:on=>:update) do\n"
            code += "  prepare_on_update\n"
            code += "end\n"
          end
          if self.instance_methods.include?("check")
            code += "validate :check\n"
          end
          if self.instance_methods.include?("check_on_update")
            code += "validate(:on=>:update) do\n"
            code += "  check_on_update\n"
            code += "end\n"
          end
          if self.instance_methods.include?("check_on_create")
            code += "validate(:on=>:create) do\n"
            code += "  check_on_create\n"
            code += "end\n"
          end
          if self.instance_methods.include?("clean")
            code += "after_validation :clean\n"
          end
          if self.instance_methods.include?("clean_on_create")
            code += "after_validation(:on=>:create) do\n"
            code += "  clean_on_create\n"
            code += "end\n"
          end
          if self.instance_methods.include?("clean_on_update")
            code += "after_validation(:on=>:update) do\n"
            code += "  clean_on_update\n"
            code += "end\n"
          end
          class_eval code
        end

      end

    end
  end
end
