class GeneralizeCustomFields < ActiveRecord::Migration

  def up
    add_column :custom_fields, :customized_type, :string
    execute "UPDATE #{quoted_table_name(:custom_fields)} SET customized_type = 'Entity'"
    change_column_null :custom_fields, :customized_type, false
    rename_column :custom_fields, :decimal_min, :minimal_value
    rename_column :custom_fields, :decimal_max, :maximal_value
    rename_column :custom_fields, :length_max, :maximal_length
    add_column :custom_fields, :minimal_length, :integer
    add_column :custom_fields, :column_name, :string

    execute("UPDATE #{quoted_table_name(:custom_fields)} SET nature = 'text' WHERE nature = 'string'")
    rename_column :custom_field_data, :string_value, :text_value

    for field in select_all("SELECT * FROM #{quoted_table_name(:custom_fields)}")
      column_name = field['name'].parameterize.gsub(/[^a-z]+/, '_').gsub(/(^\_+|\_+$)/, '').to_sym
      nature = field['nature'].to_sym
      type = nature
      if nature == :choice
        type = :string
      end
      add_column :entities, column, type
      execute("UPDATE #{quoted_table_name(:entities)} SET #{column} = cfd.#{type}_value FROM #{quoted_table_name(:custom_field_data)} AS cfd JOIN #{quoted_table_name(:custom_fields)} AS cf (cfd.custom_field_id = cf.id) WHERE cfd.entity_id = #{quoted_table_name(:entities)} AND cf.nature != 'choice'")
      execute("UPDATE #{quoted_table_name(:entities)} SET #{column} = cfc.value FROM #{quoted_table_name(:custom_field_data)} AS cfd JOIN #{quoted_table_name(:custom_fields)} AS cf (cfd.custom_field_id = cf.id) JOIN #{quoted_table_name(:custom_field_choices)} AS cfc (cfd.choice_value_id = cfc.id) WHERE cfd.entity_id = #{quoted_table_name(:entities)} AND cf.nature = 'choice'")
    end

    drop_table :custom_field_data

    # add_column :custom_field_data, :customized_type, :string
    # rename_column :custom_field_data, :entity_id, :customized_id
    # execute "UPDATE #{quoted_table_name(:custom_field_data)} SET customized_type = 'Entity'"
    # change_column_null :custom_field_data, :customized_type, false
    # remove_index :custom_field_data, :name => :index_complement_data_on_entity_id
    # rename_index :custom_field_data, :index_complement_data_on_complement_id, :index_custom_field_data_on_custom_field_id
    # add_index    :custom_field_data, [:customized_type, :customized_id], :name => :index_custom_field_data_on_customized
    # add_index    :custom_field_data, [:customized_type, :customized_id, :custom_field_id], :name => :index_custom_field_data_unique, :unique => true
  end

  def down
    create_table :custom_field_data do |t|
      t.references :entity, :null => false
      t.references :custom_field, :null => false
      t.decimal    :decimal_value, :precision => 19, :scale => 4
      t.text       :string_value
      t.boolean    :boolean_value
      t.date       :date_value
      t.datetime   :datetime_value
      t.references :choice_value
      t.stamps
    end
    add_stamps_indexes
    add_index :custom_field_data, :entity_id
    add_index :custom_field_data, :custom_field_id
    add_index :custom_field_data, :choice_value_id

    for field in select_all("SELECT * FROM #{quoted_table_name(:custom_fields)}")
      # TODO: restore data
    end

    # remove_index :custom_field_data, :name => :index_custom_field_data_unique
    # remove_index :custom_field_data, :name => :index_custom_field_data_on_customized
    # rename_index :custom_field_data, :index_custom_field_data_on_custom_field_id, :index_complement_data_on_complement_id
    # add_index :custom_field_data, :customized_id, :name => :index_complement_data_on_entity_id

    execute "DELETE FROM #{quoted_table_name(:custom_fields)} WHERE customized_type != 'entity'"
    execute "DELETE FROM #{quoted_table_name(:custom_field_data)} WHERE customized_type != 'Entity'"
    rename_column :custom_field_data, :customized_id, :entity_id
    remove_column :custom_field_data, :customized_type

    remove_column :custom_fields, :minimal_length
    rename_column :custom_fields, :maximal_length, :length_max
    rename_column :custom_fields, :maximal_value, :decimal_max
    rename_column :custom_fields, :minimal_value, :decimal_min
    remove_column :custom_fields, :customized_type
  end
end
