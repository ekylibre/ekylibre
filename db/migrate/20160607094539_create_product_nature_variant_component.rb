class CreateProductNatureVariantComponent < ActiveRecord::Migration
  def change
    create_table :product_nature_variant_components do |t|
      t.references :variant, null: false, index: true
      t.references :piece_variant, null: false, index: true
      t.string :name, null: false
      t.stamps
    end
  end
end
