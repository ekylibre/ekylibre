class AddForeignKeyToProductNatureVariant < ActiveRecord::Migration
  def change
    add_reference :product_nature_variants, :valuing, index: true
  end
end
