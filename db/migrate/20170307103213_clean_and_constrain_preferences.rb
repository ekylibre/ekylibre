class CleanAndConstrainPreferences < ActiveRecord::Migration
  def change
    # Removes preference 'products_for_intervention' used in animal Golumn. As this is a temp preference, there is no need to handle merging.
    execute <<-SQL
      DELETE FROM preferences WHERE name='products_for_intervention'
    SQL

    add_index :preferences, [:user_id, :name], unique: true
  end
end
