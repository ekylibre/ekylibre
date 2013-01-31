class GeneralizeObservations < ActiveRecord::Migration

  def up
    # remove_index :observations, :entity_id
    add_column :observations, :owner_type, :string
    add_column :observations, :observed_at, :datetime
    add_column :observations, :author_id, :integer
    rename_column :observations, :entity_id, :owner_id
    execute("UPDATE #{quoted_table_name(:observations)} SET owner_type = 'Entity', observed_at = created_at, author_id = COALESCE(creator_id, 0)")
    change_column_null :observations, :owner_type, false
    change_column_null :observations, :observed_at, false
    change_column_null :observations, :author_id, false
    add_index :observations, [:owner_id, :owner_type]
    add_index :observations, :author_id
  end

end
