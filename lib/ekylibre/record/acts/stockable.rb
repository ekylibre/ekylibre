module Ekylibre::Record
  module Acts #:nodoc:
    module Stockable #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Add methods for reconciliating
        def acts_as_stockable(*args)
          # TODO: Repair acts_as_stockable
          return nil
          options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
          stock_move = args[0].is_a?(Symbol) ? args[0] : :move
          reflection = self.reflections[stock_move]
          condition = options.delete(:if)
          origin = options.delete(:origin)
          record = self.name.underscore.to_s
          attributes = {}
          [:quantity, :product, :unit, :warehouse, :tracking, :moved_at].each do |attr|
            attributes[attr] = options.delete(attr) || attr
          end
          attributes[:origin] =  (origin ? "self.#{origin}" : "self")
          attributes[:moved_at] = "#{attributes[:origin]}.#{attributes[:moved_at]}" if attributes[:moved_at].is_a? Symbol
          attributes[:generated] = "true"
          attrs = attributes.collect{|k, v| ":#{k} => " + (v.is_a?(Symbol) ? "self.#{v}" : "(#{v})") }.join(", ")
          code  = ""
          update_method = "_update_#{stock_move}_#{__LINE__}"

          # Checks if a warehouse is provided when it is necessary
          code << "validates_presence_of :warehouse, :if => Proc.new{|#{record}| (#{record}.product and #{record}.product.stockable?)}\n"

          code << "after_destroy do |old|\n"
          code << "  old.#{stock_move}.destroy if old.#{stock_move} and not old.#{stock_move}.destroyed?\n"
          code << "end\n"

          code << "after_save do\n"
          if condition
            code << "  unless " + (condition.is_a?(Symbol) ? "self.#{condition}" : condition) +"\n"
            code << "    self.#{stock_move}.destroy if self.#{stock_move}\n"
            code << "    return\n"
            code << "  end\n"
          end
          code << "  if self.#{stock_move}\n"
          for name, value in attributes
            code << "    self.#{stock_move}.#{name} = " + (value.is_a?(Symbol) ? "self.#{value}" : value) + "\n"
          end
          code << "    self.#{stock_move}.save!\n"
          code << "  else\n"
          code << "    new_#{stock_move} = StockMove.new\n"
          for name, value in attributes
            code << "    new_#{stock_move}.#{name} = " + (value.is_a?(Symbol) ? "self.#{value}" : value) + "\n"
          end
          code << "    raise new_#{stock_move}.errors.inspect unless new_#{stock_move}.save\n"
          code << "    #{self.name}.where(:id => self.id).update_all(:#{reflection.foreign_key} => new_#{stock_move}.id)\n"
          code << "  end\n"
          code << "  self.reload\n"
          code << "end\n"

          code << "def confirm_#{stock_move}(moved_at = Date.today)\n"
          code << "  if self.#{stock_move}\n"
          code << "    self.#{stock_move}.moved_at = moved_at\n"
          code << "    self.#{stock_move}.save!\n"
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
