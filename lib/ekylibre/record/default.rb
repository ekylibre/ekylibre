module Ekylibre::Record
  module Default #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Manage 
        def has_default(*args)
          options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
          column  = args.shift || :by_default

          code  = ""
          
          scope = "self.class"
          scope_columns = []
          if s = options[:scope]
            s = [s] if s.is_a?(Symbol)
            unless s.is_a?(Symbol) or s.is_a?(Array)
              raise ArgumentError.new("Scope must be given as a Symbol or an Array of Symbol")
              scope << ".where(" + s.collect do |c|
                scope_columns << c.to_sym
                ":#{c} => self.#{c}"
              end.join(", ") + ")"
            end
          end

          code << "before_save(:set_#{column}_if_first, :on => :create)\n"
          code << "before_save(:set_#{column}_if_alone, :on => :update)\n"
          code << "after_save(:ensure_#{column}_uniqueness)\n"

          code << "def set_#{column}\n"
          code << "  self.#{column} = true\n"
          code << "  self.save\n"
          code << "end\n"

          code << "def set_#{column}!\n"
          code << "  self.#{column} = true\n"
          code << "  self.save!\n"
          code << "end\n"

          code << "def set_#{column}_if_first\n"
          code << "  self.#{column} = true if #{scope}.where(:#{column} => true).count.zero?\n"
          code << "end\n"

          code << "def set_#{column}_if_alone\n"
          code << "  self.#{column} = true if #{scope}.where('#{column} = ? AND id != ?', true, self.id).count.zero?\n"
          code << "end\n"

          code << "def ensure_#{column}_uniqueness\n"
          code << "  if self.#{column}?\n"
          code << "    #{scope}.update_all({:#{column} => false}, ['#{column} = ? AND id != ?', true, self.id]) \n"
          code << "  end\n"
          code << "end\n"

          code << "def self.#{column}(" + scope_columns.collect{|c| "#{c} = nil"}.join(', ') + ")\n"
          if scope_columns.size > 0
            code << "  raise ArgumentError.new('#{scope_columns.size} arguments expected: " + scope_columns.keys.join(", ") + "') if " + scope_columns.collect{|c| "#{c}.nil?"}.join(" or ") + "\n"
          end
          code << "  self.where(" + scope_columns.collect{|c| ":#{c} => #{c}, "}.join("") + ":#{column} => true).first\n"
          code << "end\n"

          # puts code
          class_eval code
        end
      end

  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Default)
