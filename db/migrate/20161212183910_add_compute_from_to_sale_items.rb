class AddComputeFromToSaleItems < ActiveRecord::Migration
  def change
    add_column :sale_items, :compute_from, :string
    reversible do |r|
      r.up do
        execute "UPDATE sale_items SET compute_from = 'unit_pretax_amount'"
      end
    end
    change_column_null :sale_items, :compute_from, false
  end
end
