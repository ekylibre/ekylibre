module MigrationHelper

  # Prevents errors from SQLite only
  # Renames too long index names with short names
  # At the end of the operations the indexes are renamed back.
  def protect_indexes(tables, &block)
    if adapter_name == "SQLite"
      suppress_messages do
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
      end

      # Do all the stuff with the given tables
      yield

      # Re-add annoying indexes for SQLite
      suppress_messages do
        for index in sqlite_indexes.reverse
          rename_index index.table, index.short_name, index.name
        end
      end
    else
      yield
    end  
  end

end

ActiveRecord::Migration.send(:include, MigrationHelper)
