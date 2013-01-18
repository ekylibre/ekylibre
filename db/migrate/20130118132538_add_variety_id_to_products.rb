class AddVarietyIdToProducts < ActiveRecord::Migration
  def up
    add_column :products, :variety_id, :integer
    execute "UPDATE #{quoted_table_name(:products)} SET variety_id = pn.variety_id FROM #{quoted_table_name(:product_natures)} AS pn WHERE pn.id = #{quoted_table_name(:products)}.nature_id"
    change_column_null :products, :variety_id, false
  end

  def down
    remove_column :products, :variety_id
  end
end
