module Stamp

  module SchemaStatements

    def add_stamps(table_name, options = {})
      add_column(table_name, :created_at, :datetime, :null=>false)
      add_column(table_name, :updated_at, :datetime, :null=>false)
      add_column(table_name, :creator_id, :integer)
      add_column(table_name, :updater_id, :integer)
      add_column(table_name, :lock_version, :integer, :null=>false, :default=>0)
      add_index(table_name, :created_at)
      add_index(table_name, :updated_at)
      add_index(table_name, :creator_id)
      add_index(table_name, :updater_id)
    end

  end

end
ActiveRecord::Migration.send(:include, Stamp::SchemaStatements)
