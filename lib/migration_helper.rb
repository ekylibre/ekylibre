module MigrationHelper

  # Prevents errors from SQLite only
  # Renames too long index names with short names
  # At the end of the operations the indexes are renamed back.
  def protect_indexes(tables, &block)
    if adapter_name == "SQLite"
      sqlite_indexes = []
      root, count = rand.to_s[2..-1].to_i.to_s(36), "a"
      Struct.new("ShortIndexName", :table, :name, :short_name)
      for table in tables
        for index in indexes(table)
          if index.name.length > 32
            sqlite_indexes << Struct::ShortIndexName.new(index.table, index.name, "ndx#{root}_#{count}")
            count.succ!
          end
        end
      end
      for index in sqlite_indexes
        rename_index index.table, index.name, index.short_name
      end

      # Do all the stuff with the given tables
      yield

      # Re-add annoying indexes for SQLite
      for index in sqlite_indexes.reverse
        rename_index index.table, index.short_name, index.name
      end
    else
      yield
    end  
  end


end

class ActiveRecord::ConnectionAdapters::TableDefinition

  # Appends 5 columns: created_at, creator_id, updated_at, updater_id and lock_version
  def stamps(*args)
    options = args.extract_options!
    column(:created_at, :datetime, {:null=>false}.merge(options))
    column(:creator_id, :integer, options)
    column(:updated_at, :datetime, {:null=>false}.merge(options))
    column(:updater_id, :integer, options)
    column(:lock_version, :integer, {:null=>false, :default=>0}.merge(options))
  end
end
