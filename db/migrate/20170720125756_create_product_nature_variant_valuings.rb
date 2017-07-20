class CreateProductNatureVariantValuings < ActiveRecord::Migration
  def change
    create_table :product_nature_variant_valuings do |t|

      t.timestamps null: false
    end
  end
end
