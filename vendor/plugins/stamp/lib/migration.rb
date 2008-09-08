module Stamp

  module Schema
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def self.extended(base)
        class << base
          attr_accessor :defining
          alias :defining? :defining

          alias_method_chain :define, :stamp
        end
      end

      def define_with_stamp(info={}, &block)
        begin
          self.defining = true
          define_without_stamp(info, &block)
        ensure
          self.defining = false
        end
      end
    end

  end

  module Migration
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def create_table(name, options = {})
        super do |table_defintion|
          yield table_defintion
          unless ActiveRecord::Schema.defining? || options[:stamp] == false
            table_defintion.column :created_at,   :datetime,  :null => false
            table_defintion.column :updated_at,   :datetime,  :null => false
            unless options[:userstamp] == false
              table_defintion.column :created_by,   :integer,  :references=>:users, :on_delete=>:restrict, :on_update=>:cascade
              table_defintion.column :updated_by,   :integer,  :references=>:users, :on_delete=>:restrict, :on_update=>:cascade
            end
            table_defintion.column :lock_version, :integer,   :null => false, :default => 0
          end
        end
        unless ActiveRecord::Schema.defining? || options[:stamp] == false
          add_index name.to_sym, :created_at
          add_index name.to_sym, :updated_at
          unless options[:userstamp] == false
            add_index name.to_sym, :created_by
            add_index name.to_sym, :updated_by
          end
        end
      end
    end
  end
end
