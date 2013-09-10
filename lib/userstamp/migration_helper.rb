# module Userstamp

#   module TableDefinition
#     def self.included(base) # :nodoc:
#       base.send(:include, InstanceMethods)
#     end

#     module InstanceMethods
#       def stamps
#         column(:created_at, :datetime, null: false, index: true)
#         column(:updated_at, :datetime, null: false, index: true)
#         column(:creator_id, :integer, index: true)
#         column(:updater_id, :integer, index: true)
#         column(:lock_version, :integer, null: false, default: 0)
#       end
#     end
#   end


#   module SchemaStatements

#     def add_stamps_indexes(table_name, options = {})
#       # say("DEPRECATED: Don't use add_stamps_indexes. This method is useless since t.stamps adds indexes.")
#       suppress_messages do
#         add_index(table_name, :created_at)
#         add_index(table_name, :updated_at)
#         add_index(table_name, :creator_id)
#         add_index(table_name, :updater_id)
#       end
#     end

#   end

# end
# ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Userstamp::TableDefinition)
# ActiveRecord::Migration.send(:include, Userstamp::SchemaStatements)

ActiveRecord::ConnectionAdapters::TableDefinition.class_eval do

  def stamps
    self.datetime(:created_at, null: false)
    self.datetime(:updated_at, null: false)
    self.references(:creator, index: true)
    self.references(:updater, index: true)
    self.integer(:lock_version, null: false, default: 0)
    self.index(:created_at)
    self.index(:updated_at)
  end

end
