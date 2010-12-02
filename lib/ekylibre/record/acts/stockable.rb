module Ekylibre::Record
  module Acts #:nodoc:
    module Stockable #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Add methods for reconciliating
        def acts_as_stockable(*args)
          column = args[0].is_a?(Symbol) ? args[0] : :stock_move
          options = (args[-1].is_a?(Hash) ? args[-1] : {})
          condition = options.delete(:if)
          origin = options.delete(:origin)
          variable = "self" # self.name.underscore # "self" || 
          attributes = {}
          [:quantity, :product, :unit, :warehouse, :tracking, :moved_on].each{|a| attributes[a] = a}
          attributes.merge!(options)
          attributes[:origin] =  (origin ? "#{variable}.#{origin}" : "#{variable}")
          attributes[:moved_on] = "#{attributes[:origin]}.#{attributes[:moved_on]}" if attributes[:moved_on].is_a? Symbol
          attributes[:generated] = "true"
          attributes[:company_id] = "#{variable}.company_id"
          attrs = attributes.collect{|k,v| ":#{k}=>"+(v.is_a?(String) ? "(#{v})" : "#{variable}.#{v}")}.join(", ")
          code  = ""
          update_method = "_update_#{column}_#{__LINE__}"

          # code += "before_save :#{update_method}\n"
          #WARN: BEFORE_SAVE DONT WORK VERY WELL
          code += "after_destroy do |old|\n"
          code += "  old.#{column}.destroy if old.#{column} and not old.#{column}.destroyed?\n"
          code += "end\n"

          # code += "def #{update_method}\n"
          # code += "after_save do |#{variable}|\n"
          code += "after_save do"+(variable == "self" ? "" : "|#{variable}|")+"\n"
          # code += "  puts \"#{self.name} (\#\{#{variable}.id\})\"\n"
          if condition
            code += "  unless #{condition}\n" 
            code += "    #{variable}.#{column}.destroy if #{variable}.#{column}\n" 
            code += "    return\n"
            code += "  end\n"
          end
          # code += "  puts \"#{self.name} (\#\{#{variable}.id\}) 2\"\n"
          # code += "  raise Exception.new '#{condition}'\n"
          code += "  if #{variable}.#{column}\n"
          # code += "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.1\"\n"
          code += "    #{variable}.#{column}.update_attributes!(#{attrs})\n"
          code += "  else\n"
          # code += "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.2\"\n"
          code += "    __#{column}__ = StockMove.new(#{attrs})\n"
          # code += "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.2.1\"\n"
          code += "    raise __#{column}__.errors.inspect unless __#{column}__.save\n"
          # code += "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.2.2\"\n"
          code += "    #{self.name}.update_all({:#{column}_id => __#{column}__.id}, {:id=>#{variable}.id})\n"
          # code += "    #{variable}.create_#{column}(#{attrs}, :company_id =>#{variable}.company_id)\n"
          # code += "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.3\"\n"
          code += "  end\n"
          # code += "  puts \"#{self.name} (\#\{#{variable}.id\}) 3\"\n"
          code += "  self.reload\n"
          code += "end\n"

          code += "def confirm_#{column}(moved_on=Date.today)\n"
          code += "  if self.#{column}\n"
          code += "    self.#{column}.update_attributes!(:moved_on=>moved_on)\n"
          code += "  end\n"
          code += "end\n"

          # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}

          # puts code
          # raise "Stop"
          class_eval code
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Stockable)
