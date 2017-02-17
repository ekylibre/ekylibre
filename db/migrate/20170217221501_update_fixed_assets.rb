class UpdateFixedAssets < ActiveRecord::Migration
  def change

    add_reference :purchase_items, :fixed_asset, index: true
    add_reference :fixed_assets, :product, index: true

    reversible do |r|
      r.up do
        execute 'UPDATE purchase_items pi SET fixed_asset_id = (SELECT fa.id FROM fixed_assets fa WHERE fa.purchase_item_id = pi.id LIMIT 1)'
        execute 'UPDATE fixed_assets fa SET product_id = (SELECT p.id FROM products p WHERE p.fixed_asset_id = fa.id LIMIT 1)'

      end
      r.down do
        execute 'UPDATE fixed_assets fa SET purchase_item_id = (SELECT pi.id FROM purchase_items pi WHERE fa.id = pi.fixed_asset_id LIMIT 1)'
        execute 'UPDATE products p SET fixed_asset_id = (SELECT fa.id FROM fixed_assets fa WHERE fa.product_id = p.id LIMIT 1)'
      end
    end

    remove_column :fixed_assets, :purchase_item_id
    remove_column :fixed_assets, :purchase_id
    remove_column :products, :fixed_asset_id
  end
end
