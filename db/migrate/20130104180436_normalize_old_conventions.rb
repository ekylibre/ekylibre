class NormalizeOldConventions < ActiveRecord::Migration
  def up
    change_column :products, :nature, :string, :limit => 16
    execute "UPDATE #{quoted_table_name(:products)} SET nature = 'subscription' WHERE nature = 'subscrip'"
    remove_column :products, :service_coeff

    remove_column :prices, :use_range
    remove_column :prices, :quantity_min
    remove_column :prices, :quantity_max
  end

  def down
    add_column :prices, :quantity_max, :decimal, :precision => 19, :scale => 4
    add_column :prices, :quantity_min, :decimal, :precision => 19, :scale => 4
    add_column :prices, :use_range, :boolean, :null => false, :default => false

    add_column :products, :service_coeff, :decimal, :precision => 19, :scale => 4
    execute "UPDATE #{quoted_table_name(:products)} SET nature = 'subscrip' WHERE nature = 'subscription'"
    change_column :products, :nature, :string, :limit => 8
  end
end
