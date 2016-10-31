class AddAttributesForSalesExchange < ActiveRecord::Migration
  def change
    add_column :product_nature_variants, :gtin, :string
    reversible do |d|
      d.up do
        execute "UPDATE product_nature_variants SET gtin = number WHERE number ~ '^\d{12,14}$'"
      end
    end
    add_column :entities, :codes, :jsonb
    add_column :sales, :codes, :jsonb
    add_column :sale_items, :codes, :jsonb
  end
end
