module Ekylibre::Record
  module Acts #:nodoc:
    module Stockable #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Add methods for reconciliating
        def acts_as_stockable(*args)
          stock_move = args[0].is_a?(Symbol) ? args[0] : :stock_move
          options = (args[-1].is_a?(Hash) ? args[-1] : {})
          condition = options.delete(:if)
          origin = options.delete(:origin)
          record = self.name.underscore.to_s
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
          update_method = "_update_#{stock_move}_#{__LINE__}"

          # Checks if a warehouse is provided when it is necessary
          code << "validates_presence_of :warehouse, :if => Proc.new{|#{record}| (#{record}.product and #{record}.product.stockable?)}\n"

          # code << "before_save :#{update_method}\n"
          #WARN: BEFORE_SAVE DONT WORK VERY WELL
          code << "after_destroy do |old|\n"
          code << "  old.#{stock_move}.destroy if old.#{stock_move} and not old.#{stock_move}.destroyed?\n"
          code << "end\n"

          # code << "def #{update_method}\n"
          # code << "after_save do |#{variable}|\n"
          code << "after_save do"+(variable == "self" ? "" : "|#{variable}|")+"\n"
          # code << "  puts \"#{self.name} (\#\{#{variable}.id\})\"\n"
          if condition
            code << "  unless #{condition}\n" 
            code << "    #{variable}.#{stock_move}.destroy if #{variable}.#{stock_move}\n" 
            code << "    return\n"
            code << "  end\n"
          end
          # code << "  puts \"#{self.name} (\#\{#{variable}.id\}) 2\"\n"
          # code << "  raise Exception.new '#{condition}'\n"
          code << "  if #{variable}.#{stock_move}\n"
          # code << "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.1\"\n"
          code << "    #{variable}.#{stock_move}.update_attributes!(#{attrs})\n"
          code << "  else\n"
          # code << "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.2\"\n"
          code << "    __#{stock_move}__ = StockMove.new(#{attrs})\n"
          # code << "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.2.1\"\n"
          code << "    raise __#{stock_move}__.errors.inspect unless __#{stock_move}__.save\n"
          # code << "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.2.2\"\n"
          code << "    #{self.name}.update_all({:#{stock_move}_id => __#{stock_move}__.id}, {:id=>#{variable}.id})\n"
          # code << "    #{variable}.create_#{stock_move}(#{attrs}, :company_id =>#{variable}.company_id)\n"
          # code << "    puts \"#{self.name} (\#\{#{variable}.id\}) 2.3\"\n"
          code << "  end\n"
          # code << "  puts \"#{self.name} (\#\{#{variable}.id\}) 3\"\n"
          code << "  self.reload\n"
          code << "end\n"

          code << "def confirm_#{stock_move}(moved_on=Date.today)\n"
          code << "  if self.#{stock_move}\n"
          code << "    self.#{stock_move}.update_attributes!(:moved_on=>moved_on)\n"
          code << "  end\n"
          code << "end\n"

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
