class KeepOwnCashes < ActiveRecord::Migration
  def up
    remove_column :cashes, :entity_id
  end

  def down
    add_column :cashes, :entity_id, :integer
    entity_id = select_value("SELECT id FROM #{quoted_table_name(:entities)} WHERE of_company")
    execute "UPDATE #{quoted_table_name(:cashes)} SET entity_id = #{entity_id}"
  end
end
