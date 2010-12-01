module Ekylibre::Record  #:nodoc:
  module Transfer
    def self.actions
      [:create, :update, :destroy]
    end

    class Base
      attr_reader :origin, :action, :virtual

      cattr_reader :id
      @@id = "0"

      def self.next_id
        @@id.succ!
        return @@id
      end

      def initialize(origin, action, virtual)
        raise ArgumentError.new("Unvalid action #{action.inspect} (#{Ekylibre::Record::Transfer::actions.to_sentence} are accepted)") unless Ekylibre::Record::Transfer::actions.include? action
        @origin = origin
        @action = action
        @virtual = virtual
      end

      def move(options={})
        unless use = options.delete(:use)
          use = @origin
        end
        # Find stock
        conditions = {:product_id=>use.product_id, :warehouse_id=>use.warehouse_id, :tracking_id=>use.tracking_id}
        stock = use.company.stocks.where(conditions).first
        stock = use.company.stocks.create!(conditions) if stock.nil?

        # Move stock
        stock.move(@origin, options.merge(:virtual=>@virtual))
      end
      

    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def transfer(options = {}, &block)
        raise ArgumentError.new("No given block") unless block_given?
        raise ArgumentError.new("Wrong number of arguments (#{block.arity} for 1)") unless block.arity == 1
        configuration = { :on=>Ekylibre::Record::Transfer::actions, :method_name=>:transfer, :virtual=>"self.moved_on.nil\?", :moves=>:stock_moves }
        configuration.update(options) if options.is_a?(Hash)
        raise Exception.new("Need #{configuration[:moves]} reflection. Change :moves option or create reflection") unless self.reflections.has_key? configuration[:moves]

        #configuration[:column] = configuration[:column].to_s
        method_name = configuration[:method_name].to_s
        core_method_name ||= "_#{method_name}_#{Ekylibre::Record::Transfer::Base.next_id}"
        
        code = "include Ekylibre::Record::Transfer::InstanceMethods\n"

        code += "def #{method_name}(action=:create)\n"
        code += "  #{self.name}.transaction do\n"
        code += "    self.stock_moves.clear\n"
        code += "    self.#{core_method_name}(Ekylibre::Record::Transfer::Base.new(self, action, #{configuration[:virtual]}))\n"
        code += "  end\n"
        code += "end\n"

        configuration[:on] = [configuration[:on]] if configuration[:on].is_a? Symbol and configuration[:on] != :nothing
        for action in Ekylibre::Record::Transfer::actions
          if configuration[:on].include? action
            code += "after_#{action} do \n" 
            code += "  self.#{method_name}(:#{action})\n"
            code += "end\n"
          end
        end if configuration[:on].is_a? Array

        class_eval code
        
        self.send(:define_method, core_method_name, block)
      end

    end

    module InstanceMethods
    end 

  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Transfer)
