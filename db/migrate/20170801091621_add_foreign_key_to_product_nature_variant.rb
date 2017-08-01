class AddForeignKeyToProductNatureVariant < ActiveRecord::Migration
  def change
    add_reference :product_nature_variants, :valuing, index: true
    # add_foreign_key :product_nature_variants, :product_nature_variant_valuings
  end
end
