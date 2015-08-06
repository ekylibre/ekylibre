class ReviewProductTaxation < ActiveRecord::Migration
  def change
    create_table :product_nature_category_taxations do |t|
      t.references :product_nature_category,    null: false
      t.references :tax,                        null: false, index: true
      t.string :usage, null: false
      t.stamps
      t.index :product_nature_category_id, name: 'index_product_nature_category_taxations_on_category_id'
      t.index :usage
    end

    execute "INSERT INTO product_nature_category_taxations (product_nature_category_id, tax_id, usage) SELECT product_nature_category_id, tax_id, 'sale' FROM product_nature_categories_sale_taxes"

    execute "INSERT INTO product_nature_category_taxations (product_nature_category_id, tax_id, usage) SELECT product_nature_category_id, tax_id, 'purchase' FROM product_nature_categories_purchase_taxes"

    drop_table :product_nature_categories_sale_taxes

    drop_table :product_nature_categories_purchase_taxes
  end
end
