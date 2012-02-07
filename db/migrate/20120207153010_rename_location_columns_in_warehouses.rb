class RenameLocationColumnsInWarehouses < ActiveRecord::Migration
  COLUMNS = {
    :warehouses => {:x => :division, :y => :subdivision, :z => :subsubdivision},
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}

  def up
    for table, renamings in COLUMNS
      for old_column, new_column in renamings
        rename_column table, old_column, new_column
        execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new_column}', name = REPLACE(name, '#{old_column}', '#{new_column}') WHERE name LIKE '#{old_column}' AND attribute_name LIKE '#{table.to_s.singularize}%.#{old_column}'"
      end
    end
  end

  def down
    for table, renamings in COLUMNS.reverse
      for new_column, old_column in renamings
        execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new_column}', name = REPLACE(name, '#{old_column}', '#{new_column}') WHERE name LIKE '#{old_column}' AND attribute_name LIKE '#{table.to_s.singularize}%.#{old_column}'"
        rename_column table, old_column, new_column
      end
    end
  end
end
