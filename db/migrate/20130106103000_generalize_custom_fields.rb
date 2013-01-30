class GeneralizeCustomFields < ActiveRecord::Migration

  def up
    add_column :custom_fields, :used_with, :string
    execute "UPDATE #{quoted_table_name(:custom_fields)} SET used_with = 'entity'"
    change_column_null :custom_fields, :used_with, false
    rename_column :custom_fields, :decimal_min, :minimal_value
    rename_column :custom_fields, :decimal_max, :maximal_value
    rename_column :custom_fields, :length_max, :maximal_length
    add_column :custom_fields, :minimal_length, :integer, :null => false, :default => 0

    add_column :custom_field_data, :customized_type, :string
    rename_column :custom_field_data, :entity_id, :customized_id
    execute "UPDATE #{quoted_table_name(:custom_field_data)} SET customized_type = 'Entity'"
    change_column_null :custom_field_data, :customized_type, false
    remove_index :custom_field_data, :name => :index_complement_data_on_entity_id
    rename_index :custom_field_data, :index_complement_data_on_complement_id, :index_custom_field_data_on_custom_field_id
    add_index    :custom_field_data, [:customized_type, :customized_id], :name => :index_custom_field_data_on_customized
    add_index    :custom_field_data, [:customized_type, :customized_id, :custom_field_id], :name => :index_custom_field_data_unique, :unique => true
  end

  def down
    remove_index :custom_field_data, :name => :index_custom_field_data_unique
    remove_index :custom_field_data, :name => :index_custom_field_data_on_customized
    rename_index :custom_field_data, :index_custom_field_data_on_custom_field_id, :index_complement_data_on_complement_id
    add_index :custom_field_data, :customized_id, :name => :index_complement_data_on_entity_id

    execute "DELETE FROM #{quoted_table_name(:custom_fields)} WHERE used_with != 'entity'"
    execute "DELETE FROM #{quoted_table_name(:custom_field_data)} WHERE customized_type != 'Entity'"
    rename_column :custom_field_data, :customized_id, :entity_id
    remove_column :custom_field_data, :customized_type

    remove_column :custom_fields, :minimal_length
    rename_column :custom_fields, :maximal_length, :length_max
    rename_column :custom_fields, :maximal_value, :decimal_max
    rename_column :custom_fields, :minimal_value, :decimal_min
    remove_column :custom_fields, :used_with
  end
end
