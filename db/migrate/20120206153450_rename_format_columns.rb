# Renames 'format' columns which are incompatible with Rails 3.2
# New names are given to these columns
class RenameFormatColumns < ActiveRecord::Migration
  COLUMNS = {
    :currencies => {:format => :value_format},
    :entity_natures => {:format => :full_name_format},
    :sequences => {:format => :number_format}
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}

  RIGHTS = {
    :chnage_prices_on_sales => :change_prices_on_sales
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}

  def up
    for table, renamings in COLUMNS
      for old_column, new_column in renamings
        rename_column table, old_column, new_column
        execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new_column}', name = REPLACE(name, '#{old_column}', '#{new_column}') WHERE name LIKE '#{old_column}' AND attribute_name LIKE '#{table.to_s.singularize}%.#{old_column}'"
      end
    end

    # Fix bad name of right "change_prices_on_sales"
    for o, n in RIGHTS
      execute "UPDATE #{quoted_table_name(:users)} SET rights=REPLACE(rights, '#{o}', '#{n}')"
      execute "UPDATE #{quoted_table_name(:roles)} SET rights=REPLACE(rights, '#{o}', '#{n}')"
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
