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
          variable = self.name.underscore
          attributes = {}
          [:quantity, :product, :unit, :warehouse, :tracking].each{|a| attributes[a] = a}
          attributes.merge!(options)
          attributes[:origin] =  (origin ? "#{variable}.#{origin}" : "#{variable}")
          attrs = attributes.collect{|k,v| ":#{k} => "+(v.is_a?(String) ? "(#{v})" : "#{variable}.#{v}")}.join(", ")
          code  = ""
          update_method = "_update_#{column}_#{__LINE__}"

          # code += "before_save :#{update_method}\n"

#           code += "after_destroy do |old|\n"
#           code += "  old.#{column}.destroy if old.#{column}\n"
#           code += "end\n"

          # code += "def #{update_method}\n"
          code += "before_validation do |#{variable}|\n"
          # code += "  raise Exception.new([a, b].inspect)\n"
          # code += "  debugger\n"
          code += "  puts \"#{self.name} (\#\{self.id\})\"\n"
          if condition
            code += "  unless #{condition}\n" 
            code += "    #{variable}.#{column}.destroy if #{variable}.#{column}\n" 
            code += "    return\n"
            code += "  end\n"
          end
          code += "  puts \"#{self.name} (\#\{self.id\}) 2\"\n"
          # code += "  raise Exception.new '#{condition}'\n"
          code += "  if #{variable}.#{column}\n"
          code += "    puts \"#{self.name} (\#\{self.id\}) 2.1\"\n"
          code += "    #{variable}.#{column}.update_attributes!(#{attrs})\n"
          code += "  else\n"
          code += "    puts \"#{self.name} (\#\{self.id\}) 2.2\"\n"
          code += "    __#{column}__ = StockMove.new(#{attrs}, :company_id=>#{variable}.company_id)\n"
          code += "    puts \"#{self.name} (\#\{self.id\}) 2.2.1\"\n"
          code += "    puts __#{column}__.valid?.inspect\n"
          code += "    puts __#{column}__.errors.inspect\n"
          code += "    puts __#{column}__.inspect\n"
          code += "    puts __#{column}__.inspect unless __#{column}__.save(:validate=>true)\n"
          code += "    puts \"#{self.name} (\#\{self.id\}) 2.2.2\"\n"
          code += "    #{variable}.#{column}_id = __#{column}__.id\n"
          # code += "    #{variable}.create_#{column}(#{attrs}, :company_id =>#{variable}.company_id)\n"
          code += "    puts \"#{self.name} (\#\{self.id\}) 2.3\"\n"
          code += "  end\n"
          code += "  puts \"#{self.name} (\#\{self.id\}) 3\"\n"
          code += "end\n"

          code += "def confirm_#{column}(moved_on=Date.today)\n"
          code += "  if self.#{column}\n"
          code += "    self.#{column}.update_attributes!(:virtual=>false, :moved_on=>moved_on)\n"
          code += "  end\n"
          code += "end\n"

          # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}

          puts code
          raise "Stop"
          class_eval code
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Stockable)
