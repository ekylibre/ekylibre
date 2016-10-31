class RenameItemsCountToItemsCountValueInInspectionTables < ActiveRecord::Migration
  def change
    rename_column :inspection_points, :items_count, :items_count_value
    rename_column :inspection_calibrations, :items_count, :items_count_value

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE preferences
          SET string_value = CASE WHEN string_value LIKE 'items'THEN 'items_count'
                                  WHEN string_value LIKE 'mass' THEN 'net_mass'
                                  ELSE 'items_count' END
          WHERE name ~ 'activity_.+_inspection_view_unit'
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE preferences
          SET string_value = CASE WHEN string_value LIKE 'items_count'THEN 'items'
                                  WHEN string_value LIKE 'net_mass' THEN 'mass'
                                  ELSE 'items' END
          WHERE name ~ 'activity_.+_inspection_view_unit'
        SQL
      end
    end
  end
end
