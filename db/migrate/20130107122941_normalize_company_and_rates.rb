class NormalizeCompanyAndRates < ActiveRecord::Migration
  RATES = {
    :entities => :reduction_rate,
    :sale_natures => :downpayment_rate,
    :subscription_natures => :reduction_rate
  }.to_a.freeze
  PERCENTS = {
    :entities => :maximum_grantable_reduction_percent,
    :incoming_payment_modes => :commission_percent,
    :sale_lines => :reduction_percent
  }.to_a.freeze

  def up
    change_table :companies do |t|
      t.references :creator
      t.datetime :created_at
      t.references :updater
      t.datetime :updated_at
      t.integer :lock_version, :null => false, :default => 0
    end

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

    for table, column in RATES
      execute("UPDATE #{quoted_table_name(table)} SET #{column} = 100 * #{column}")
      change_column table, column, :decimal, :precision => 19, :scale => 4
      rename_column table, column, column.to_s.gsub(/_rate$/, "_percentage").to_sym
    end
    for table, column in PERCENTS
      rename_column table, column, column.to_s.gsub(/_percent$/, "_percentage").to_sym
    end

    rename_column :entities, :maximum_grantable_reduction_percentage, :maximal_grantable_reduction_percentage

    change_column :taxes, :nature, :string, :limit => 16
    execute "UPDATE #{quoted_table_name(:taxes)} SET nature = 'percentage' WHERE nature = 'percent'"

    rename_column :entities, :username, :user_name
  end

  def down
    rename_column :entities, :user_name, :username

    execute "UPDATE #{quoted_table_name(:taxes)} SET nature = 'percent' WHERE nature = 'percentage'"
    change_column :taxes, :nature, :string, :limit => 8

    rename_column :entities, :maximal_grantable_reduction_percentage, :maximum_grantable_reduction_percentage

    for table, column in PERCENTS.reverse
      rename_column table, column.to_s.gsub(/_percent$/, "_percentage").to_sym, column
    end
    for table, column in RATES.reverse
      rename_column table, column.to_s.gsub(/_rate$/, "_percentage").to_sym, column
      change_column table, column, :decimal, :precision => 19, :scale => 10
      execute("UPDATE #{quoted_table_name(table)} SET #{column} = #{column} / 100")
    end

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

    change_table :companies do |t|
      t.remove :creator_id
      t.remove :created_at
      t.remove :updater_id
      t.remove :updated_at
      t.remove :lock_version
    end

  end
end
