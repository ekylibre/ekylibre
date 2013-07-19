module Userstamp

  module TableDefinition
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def stamps
        column(:created_at, :datetime, :null => false)
        column(:updated_at, :datetime, :null => false)
        column(:creator_id, :integer)
        column(:updater_id, :integer)
        column(:lock_version, :integer, :null => false, :default => 0)
      end
    end
  end


  module SchemaStatements

    def add_stamps_indexes(table_name, options = {})
      # say("DEPRECATED: Don't use add_stamps_indexes. This method is useless since t.stamps adds indexes.")
      suppress_messages do
        add_index(table_name, :created_at)
        add_index(table_name, :updated_at)
        add_index(table_name, :creator_id)
        add_index(table_name, :updater_id)
      end
    end

  end

end
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Userstamp::TableDefinition)
ActiveRecord::Migration.send(:include, Userstamp::SchemaStatements)
